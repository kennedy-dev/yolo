const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const upload = multer();

const productRoute = require('./routes/api/productRoute');

// Connecting to the Database
let mongodb_url = 'mongodb://app-ferretdb:27017/';
let dbName = 'yolomy';

// define a url to connect to the database
const MONGODB_URI = process.env.MONGODB_URI || mongodb_url + dbName;

// Connect to MongoDB via FerretDB (removed deprecated options)
mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('Database connected successfully via FerretDB');
  })
  .catch((error) => {
    console.log('Database connection error:', error);
  });

let db = mongoose.connection;

// Check Connection
db.once('open', () => {
    console.log('Database connected successfully')
});

// Check for DB Errors
db.on('error', (error) => {
    console.log(error);
});

// Initializing express
const app = express();

// Body parser middleware
app.use(express.json());

// Multer middleware
app.use(upload.array()); 

// Cors 
app.use(cors());

// Use Route
app.use('/api/products', productRoute);

// Define the PORT
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`)
});