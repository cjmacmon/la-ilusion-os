const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Token requerido' });
  }
  const token = header.slice(7);
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || 'hacienda_la_ilusion_secret_2026');
    next();
  } catch {
    res.status(401).json({ success: false, error: 'Token inválido o expirado' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.rol)) {
      return res.status(403).json({ success: false, error: 'Acceso denegado' });
    }
    next();
  };
}

module.exports = { requireAuth, requireRole };
