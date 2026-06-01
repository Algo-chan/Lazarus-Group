const express = require('express');
const Joi = require('joi');
const {
  usersDB,
  servicesDB,
  chatsDB,
  messagesDB,
} = require('../database');
const {
  nowIso,
  sanitizeUser,
  sanitizeService,
  sanitizeChat,
  emitNotification,
} = require('../utils/appHelpers');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

const createChatSchema = Joi.object({
  serviceId: Joi.string().optional(),
  providerId: Joi.string().optional(),
  customerId: Joi.string().optional(),
}).or('serviceId', 'providerId', 'customerId');

const messageSchema = Joi.object({
  text: Joi.string().trim().min(1).max(2000).required(),
});

const resolveParticipants = async (req, value) => {
  let service = null;
  let providerId = value.providerId || null;
  let customerId = value.customerId || null;

  if (value.serviceId) {
    service = await servicesDB.findOne({ _id: value.serviceId });
    if (!service) {
      return { error: 'Service not found' };
    }
    providerId = providerId || service.provider_id || null;
  }

  if (req.user.role === 'customer') {
    customerId = req.user.id;
  } else if (req.user.role === 'provider') {
    providerId = req.user.id;
  }

  if (!providerId || !customerId) {
    return { error: 'Both customer and provider are required for a chat' };
  }

  const customer = await usersDB.findOne({ _id: customerId });
  const provider = await usersDB.findOne({ _id: providerId });
  if (!customer || !provider) {
    return { error: 'Chat participants not found' };
  }
  if (customer.role !== 'customer') {
    return { error: 'Chat customer must have customer role' };
  }
  if (provider.role !== 'provider') {
    return { error: 'Chat provider must have provider role' };
  }

  return {
    customer,
    provider,
    service,
    customerId,
    providerId,
  };
};

const ensureMembership = (chat, userId) => {
  if (!chat || (chat.customer_id !== userId && chat.provider_id !== userId)) {
    return false;
  }
  return true;
};

router.use(authenticate);

router.post('/', async (req, res) => {
  try {
    const { error, value } = createChatSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const resolved = await resolveParticipants(req, value);
    if (resolved.error) {
      return res.status(400).json({ message: resolved.error });
    }

    const { customerId, providerId, service } = resolved;
    let chat = await chatsDB.findOne({
      customer_id: customerId,
      provider_id: providerId,
    });

    if (!chat) {
      chat = await chatsDB.insert({
        customer_id: customerId,
        provider_id: providerId,
        service_id: service?._id ?? value.serviceId ?? null,
        created_at: nowIso(),
        updated_at: nowIso(),
        last_message_at: nowIso(),
        last_message_preview: '',
      });
    } else if (service && !chat.service_id) {
      await chatsDB.update({ _id: chat._id }, { $set: { service_id: service._id, updated_at: nowIso() } });
      chat = await chatsDB.findOne({ _id: chat._id });
    }

    const unreadCount = await messagesDB.count({
      chatId: chat._id,
      senderId: { $ne: req.user.id },
      read: false,
    });

    const otherUserId = chat.customer_id === req.user.id ? chat.provider_id : chat.customer_id;
    const otherUser = await usersDB.findOne({ _id: otherUserId });

    res.status(200).json(
      sanitizeChat(chat, {
        unreadCount,
        otherUser: sanitizeUser(otherUser),
        service: chat.service_id ? sanitizeService(await servicesDB.findOne({ _id: chat.service_id })) : null,
      })
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/', async (req, res) => {
  try {
    const chats = await chatsDB.find({
      $or: [{ customer_id: req.user.id }, { provider_id: req.user.id }],
    }).sort({ last_message_at: -1, updated_at: -1 });

    const enriched = await Promise.all(
      chats.map(async (chat) => {
        const otherUserId = chat.customer_id === req.user.id ? chat.provider_id : chat.customer_id;
        const otherUser = await usersDB.findOne({ _id: otherUserId });
        const service = chat.service_id ? await servicesDB.findOne({ _id: chat.service_id }) : null;
        const unreadCount = await messagesDB.count({
          chatId: chat._id,
          senderId: { $ne: req.user.id },
          read: false,
        });
        const lastMessages = await messagesDB.find({ chatId: chat._id }).sort({ timestamp: -1 }).limit(1);
        const lastMessage = lastMessages[0];

        return sanitizeChat(chat, {
          unreadCount,
          otherUser: sanitizeUser(otherUser),
          service: service ? sanitizeService(service) : null,
          lastMessagePreview: lastMessage?.text ?? chat.last_message_preview ?? '',
        });
      })
    );

    res.status(200).json(enriched);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:chatId/messages', async (req, res) => {
  try {
    const chat = await chatsDB.findOne({ _id: req.params.chatId });
    if (!ensureMembership(chat, req.user.id)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || '50', 10), 1), 50);
    const skip = (page - 1) * limit;
    const total = await messagesDB.count({ chatId: req.params.chatId });
    const messages = await messagesDB.find({ chatId: req.params.chatId }).sort({ timestamp: 1 }).skip(skip).limit(limit);

    res.status(200).json({
      chatId: req.params.chatId,
      total,
      page,
      limit,
      messages: messages.map((message) => ({
        _id: message._id,
        chatId: message.chatId,
        senderId: message.senderId,
        text: message.text,
        timestamp: message.timestamp,
        read: !!message.read,
      })),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/:chatId/messages', async (req, res) => {
  try {
    const chat = await chatsDB.findOne({ _id: req.params.chatId });
    if (!ensureMembership(chat, req.user.id)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const { error, value } = messageSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const message = await messagesDB.insert({
      chatId: req.params.chatId,
      senderId: req.user.id,
      text: value.text,
      timestamp: nowIso(),
      read: false,
    });

    const otherUserId = chat.customer_id === req.user.id ? chat.provider_id : chat.customer_id;
    await chatsDB.update(
      { _id: chat._id },
      {
        $set: {
          last_message_at: message.timestamp,
          last_message_preview: value.text.slice(0, 120),
          updated_at: nowIso(),
        },
      }
    );

    const io = req.app.get('io');
    if (io) {
      io.to(req.params.chatId).emit('new_message', {
        _id: message._id,
        chatId: message.chatId,
        senderId: message.senderId,
        text: message.text,
        timestamp: message.timestamp,
        read: false,
      });
    }

    const recipient = await usersDB.findOne({ _id: otherUserId });
    if (recipient) {
      await emitNotification(io, {
        userId: recipient._id,
        type: 'new_message',
        message: `${req.user.name} sent you a message`,
        relatedId: chat._id,
      });
    }

    res.status(201).json({
      _id: message._id,
      chatId: message.chatId,
      senderId: message.senderId,
      text: message.text,
      timestamp: message.timestamp,
      read: false,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:chatId/read', async (req, res) => {
  try {
    const chat = await chatsDB.findOne({ _id: req.params.chatId });
    if (!ensureMembership(chat, req.user.id)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const updatedCount = await messagesDB.update(
      { chatId: req.params.chatId, senderId: { $ne: req.user.id }, read: false },
      { $set: { read: true } },
      { multi: true }
    );

    res.status(200).json({ message: 'Messages marked as read', updated: updatedCount });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
