const express = require('express');
const router = express.Router();

// Load Product model
const Product = require('../../models/Products');

// GET api/products
// Get All Products
router.get('/', async (req, res) => {
    try {
        const products = await Product.find();
        res.json(products);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST api/products
// Add A Product
router.post('/', async (req, res) => {
    try {
        const newProduct = new Product({
            name: req.body.name,
            description: req.body.description,
            category: req.body.category,
            quantity: req.body.quantity,
            price: req.body.price,
            image: req.files.image
        });
        
        const savedProduct = await newProduct.save();
        res.json(savedProduct);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE api/products/:id
// Delete A Product
router.delete('/:id', async (req, res) => {
    try {
        const deletedProduct = await Product.findByIdAndDelete(req.params.id);
        if (!deletedProduct) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json({ success: true, message: 'Product deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;