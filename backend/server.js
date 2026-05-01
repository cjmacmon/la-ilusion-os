require('dotenv').config();
const express = require('express');
const cors = require('cors');
const initDatabase = require('./db/init');

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' }));

// Routes
app.use('/auth',          require('./routes/auth'));
app.use('/trabajadores',  require('./routes/trabajadores'));
app.use('/lotes',         require('./routes/lotes'));
app.use('/cosecha',       require('./routes/cosecha'));
app.use('/fertilizacion', require('./routes/fertilizacion'));
app.use('/ausencias',     require('./routes/ausencias'));
app.use('/tarifas',       require('./routes/tarifas'));
app.use('/incentivos',    require('./routes/incentivos'));
app.use('/liquidacion',   require('./routes/liquidacion'));
app.use('/dashboard',     require('./routes/dashboard'));
app.use('/gamificacion',  require('./routes/gamificacion'));
app.use('/tarifas-laboral', require('./routes/tarifas_laboral'));

app.get('/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

const PORT = process.env.PORT || 3000;

initDatabase()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log('Endpoints:');
      console.log('  POST /auth/login');
      console.log('  GET  /trabajadores');
      console.log('  POST /trabajadores');
      console.log('  PUT  /trabajadores/:id');
      console.log('  GET  /trabajadores/:id/resumen');
      console.log('  GET  /lotes');
      console.log('  POST /lotes');
      console.log('  PUT  /lotes/:id');
      console.log('  GET  /cosecha');
      console.log('  POST /cosecha');
      console.log('  POST /cosecha/sync');
      console.log('  GET  /fertilizacion');
      console.log('  POST /fertilizacion/sync');
      console.log('  GET  /ausencias');
      console.log('  POST /ausencias');
      console.log('  GET  /tarifas');
      console.log('  POST /tarifas');
      console.log('  GET  /incentivos');
      console.log('  POST /incentivos');
      console.log('  PUT  /incentivos/:id');
      console.log('  POST /liquidacion/calcular');
      console.log('  POST /liquidacion');
      console.log('  GET  /liquidacion');
      console.log('  PUT  /liquidacion/:id/estado');
      console.log('  GET  /liquidacion/export/csv');
      console.log('  GET  /dashboard/kpis');
      console.log('  GET  /gamificacion/:cod_cosechero/hoy');
    });
  })
  .catch((err) => {
    console.error('[init] Fatal: could not initialise database. Exiting.', err.message);
    process.exit(1);
  });
