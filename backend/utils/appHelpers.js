const {
  usersDB,
  servicesDB,
  bookingsDB,
  reviewsDB,
  chatsDB,
  messagesDB,
  auditLogsDB,
  notificationsDB,
} = require('../database');

const nowIso = () => new Date().toISOString();

const sanitizeUser = (user) => {
  if (!user) return null;
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone ?? null,
    role: user.role,
    profile_image: user.profile_image ?? null,
    is_verified: !!user.is_verified,
    is_active: user.is_active !== false,
    created_at: user.created_at,
    updated_at: user.updated_at,
  };
};

const sanitizeService = (service) => {
  if (!service) return null;
  return {
    id: service._id,
    title: service.title,
    category: service.category,
    provider: service.provider,
    provider_id: service.provider_id ?? null,
    rating: Number(service.avgRating ?? service.rating ?? 0),
    avgRating: Number(service.avgRating ?? service.rating ?? 0),
    reviewCount: Number(service.reviewCount ?? service.reviewsCount ?? 0),
    reviewsCount: Number(service.reviewCount ?? service.reviewsCount ?? 0),
    price: service.price,
    description: service.description,
    image: service.image,
    location: service.location,
    verified: !!service.verified,
    contact_phone: service.contact_phone ?? null,
    contact_whatsapp: service.contact_whatsapp ?? null,
    created_at: service.created_at,
    updated_at: service.updated_at,
  };
};

const sanitizeBooking = async (booking) => {
  if (!booking) return null;
  const service = booking.service_id ? await servicesDB.findOne({ _id: booking.service_id }) : null;
  const customer = booking.customer_id ? await usersDB.findOne({ _id: booking.customer_id }) : null;
  const provider = booking.provider_id ? await usersDB.findOne({ _id: booking.provider_id }) : null;

  return {
    id: booking._id,
    serviceId: booking.service_id,
    serviceName: booking.service_title || service?.title || '',
    providerId: booking.provider_id,
    providerName: booking.provider_name || provider?.name || service?.provider || '',
    customerId: booking.customer_id,
    customerName: booking.customer_name || customer?.name || '',
    date: booking.date ?? booking.scheduled_date ?? '',
    timeSlot: booking.timeSlot ?? '',
    notes: booking.notes ?? booking.description ?? '',
    status: booking.status,
    createdAt: booking.created_at,
    updatedAt: booking.updated_at,
  };
};

const sanitizeReview = async (review) => {
  if (!review) return null;
  const user = review.customer_id ? await usersDB.findOne({ _id: review.customer_id }) : null;
  return {
    id: review._id,
    serviceId: review.service_id,
    providerId: review.provider_id,
    customerId: review.customer_id,
    reviewerName: review.customer_name || user?.name || 'Anonymous',
    rating: review.rating,
    comment: review.comment ?? '',
    createdAt: review.created_at,
  };
};

const sanitizeChat = (chat, extras = {}) => ({
  id: chat._id,
  serviceId: chat.service_id ?? null,
  customerId: chat.customer_id,
  providerId: chat.provider_id,
  createdAt: chat.created_at,
  updatedAt: chat.updated_at,
  lastMessageAt: chat.last_message_at ?? chat.updated_at ?? chat.created_at,
  lastMessagePreview: extras.lastMessagePreview ?? chat.last_message_preview ?? '',
  unreadCount: extras.unreadCount ?? 0,
  otherUser: extras.otherUser ?? null,
  service: extras.service ?? null,
});

const recalculateServiceStats = async (serviceId) => {
  const reviews = await reviewsDB.find({ service_id: serviceId });
  const reviewCount = reviews.length;
  const avgRating = reviewCount
    ? reviews.reduce((sum, review) => sum + Number(review.rating || 0), 0) / reviewCount
    : 0;
  await servicesDB.update(
    { _id: serviceId },
    {
      $set: {
        avgRating: Number(avgRating.toFixed(2)),
        reviewCount,
        rating: Number(avgRating.toFixed(2)),
        reviewsCount: reviewCount,
        updated_at: nowIso(),
      },
    }
  );
  return { avgRating: Number(avgRating.toFixed(2)), reviewCount };
};

const createAuditLog = async ({ adminId, action, targetId, details }) => {
  await auditLogsDB.insert({
    admin_id: adminId,
    action,
    target_id: targetId ?? null,
    details: details ?? {},
    timestamp: nowIso(),
  });
};

const emitNotification = async (io, payload) => {
  const notification = await notificationsDB.insert({
    userId: payload.userId,
    type: payload.type,
    message: payload.message,
    relatedId: payload.relatedId ?? null,
    read: false,
    createdAt: payload.createdAt ?? nowIso(),
  });

  if (io) {
    io.to(`user_${payload.userId}`).emit('notification', notification);
  }

  return notification;
};

const notifyUsers = async (io, userIds, payloadFactory) => {
  const notifications = [];
  for (const userId of userIds.filter(Boolean)) {
    notifications.push(await emitNotification(io, { userId, ...payloadFactory(userId) }));
  }
  return notifications;
};

const getUnreadCount = async (userId) => {
  return notificationsDB.count({ userId, read: false });
};

module.exports = {
  nowIso,
  sanitizeUser,
  sanitizeService,
  sanitizeBooking,
  sanitizeReview,
  sanitizeChat,
  recalculateServiceStats,
  createAuditLog,
  emitNotification,
  notifyUsers,
  getUnreadCount,
};
