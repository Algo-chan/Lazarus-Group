const ROLES = {
  ADMIN: 'admin',
  PROVIDER: 'provider',
  CUSTOMER: 'customer',
};

const ROLE_HIERARCHY = {
  admin: 3,
  provider: 2,
  customer: 1,
};

const allowRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        message: 'Insufficient permissions',
        required_roles: roles,
        your_role: req.user.role,
      });
    }

    next();
  };
};

const allowAboveRole = (minimumRole) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    const userLevel = ROLE_HIERARCHY[req.user.role] || 0;
    const minLevel = ROLE_HIERARCHY[minimumRole] || 0;

    if (userLevel < minLevel) {
      return res.status(403).json({
        message: 'Insufficient permissions',
        minimum_role: minimumRole,
        your_role: req.user.role,
      });
    }

    next();
  };
};

module.exports = { ROLES, ROLE_HIERARCHY, allowRoles, allowAboveRole };
