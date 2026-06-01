const express = require('express');
const { usersDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');
const { createAuditLog } = require('../utils/appHelpers');

const router = express.Router();

router.patch('/:id/verify', authenticate, allowRoles(ROLES.ADMIN), async (req, res) => {
  try {
    const targetUser = await usersDB.findOne({ _id: req.params.id });
    if (!targetUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (targetUser.role !== 'provider') {
      return res.status(400).json({ message: 'Only providers can be verified' });
    }

    const verified = req.body.verified !== undefined ? !!req.body.verified : true;
    await usersDB.update(
      { _id: req.params.id },
      { $set: { is_verified: verified, updated_at: new Date().toISOString() } }
    );
    await createAuditLog({
      adminId: req.user.id,
      action: verified ? 'VERIFY_PROVIDER' : 'UNVERIFY_PROVIDER',
      targetId: req.params.id,
      details: { verified },
    });

    res.status(200).json({ message: `Provider ${verified ? 'verified' : 'unverified'}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
