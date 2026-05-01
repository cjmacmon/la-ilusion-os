const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db/pool');

// POST /auth/login
// Admin/supervisor: cedula + password
// Field worker: cod_cosechero + 4-digit PIN
router.post('/login', async (req, res) => {
  const { cedula, cod_cosechero, password, pin } = req.body;

  try {
    let trabajador;

    if (cod_cosechero && pin) {
      // Field worker login by cod_cosechero + PIN
      const result = await pool.query(
        'SELECT * FROM trabajador WHERE cod_cosechero = $1 AND activo = TRUE',
        [cod_cosechero]
      );
      trabajador = result.rows[0];
      if (!trabajador || trabajador.pin !== String(pin)) {
        return res.status(401).json({ success: false, error: 'Código o PIN incorrecto' });
      }
    } else if (cedula && password) {
      // Admin/supervisor login by cedula + password
      const result = await pool.query(
        'SELECT * FROM trabajador WHERE cedula = $1 AND activo = TRUE',
        [cedula]
      );
      trabajador = result.rows[0];
      if (!trabajador || !trabajador.password_hash) {
        return res.status(401).json({ success: false, error: 'Cédula o contraseña incorrecta' });
      }
      const valid = await bcrypt.compare(password, trabajador.password_hash);
      if (!valid) {
        return res.status(401).json({ success: false, error: 'Cédula o contraseña incorrecta' });
      }
    } else {
      return res.status(400).json({ success: false, error: 'Credenciales incompletas' });
    }

    const token = jwt.sign(
      {
        trabajador_id: trabajador.trabajador_id,
        cod_cosechero: trabajador.cod_cosechero,
        nombre_completo: trabajador.nombre_completo,
        rol: trabajador.rol,
        zona: trabajador.zona,
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      data: {
        token,
        trabajador: {
          trabajador_id: trabajador.trabajador_id,
          cod_cosechero: trabajador.cod_cosechero,
          nombre_completo: trabajador.nombre_completo,
          rol: trabajador.rol,
          zona: trabajador.zona,
        },
      },
    });
  } catch (err) {
    console.error('[auth/login]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
