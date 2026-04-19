const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    const userRole = req.user.role; // From JWT token (set by authenticateToken middleware)

    if (!userRole) {
      return res.status(403).json({ error: 'Access denied. No role found.' });
    }

    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({ 
        error: `Access denied. Required role: ${allowedRoles.join(' or ')}` 
      });
    }

    next();
  };
};

module.exports = { checkRole };