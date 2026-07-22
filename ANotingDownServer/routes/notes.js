const express = require('express');
const Note = require('../models/Note');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

router.use(requireAuth);

router.post('/', async (req, res) => {
  try {
    const { title, content } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    const note = new Note({
      userId: req.session.userId,
      title,
      content,
      lastUpdated: new Date()
    });

    await note.save();

    res.status(201).json({
      success: true,
      message: 'Note created successfully',
      note: {
        id: note._id,
        title: note.title,
        content: note.content,
        lastUpdated: note.lastUpdated,
        createdAt: note.createdAt
      }
    });
  } catch (error) {
    console.error('Create note error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error creating note'
    });
  }
});

router.get('/', async (req, res) => {
  try {
    const { search, sortBy = 'lastUpdated', sortOrder = 'desc', limit = 50, skip = 0 } = req.query;
    
    // Build query
    let query = { userId: req.session.userId };
    
    // Add search functionality
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { content: { $regex: search, $options: 'i' } }
      ];
    }

    // Build sort object
    const sortObj = {};
    sortObj[sortBy] = sortOrder === 'asc' ? 1 : -1;

    const notes = await Note.find(query)
      .sort(sortObj)
      .limit(parseInt(limit))
      .skip(parseInt(skip))
      .select('title content lastUpdated createdAt');

    res.json({
      success: true,
      notes: notes.map(note => ({
        id: note._id,
        title: note.title,
        content: note.content,
        lastUpdated: note.lastUpdated,
        createdAt: note.createdAt
      })),
      pagination: {
        limit: parseInt(limit),
        skip: parseInt(skip),
        total: await Note.countDocuments(query)
      }
    });
  } catch (error) {
    console.error('Get notes error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error fetching notes'
    });
  }
});

router.get('/:noteId', async (req, res) => {
  try {
    const note = await Note.findOne({
      _id: req.params.noteId,
      userId: req.session.userId
    });

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Note not found'
      });
    }

    res.json({
      success: true,
      note: {
        id: note._id,
        title: note.title,
        content: note.content,
        lastUpdated: note.lastUpdated,
        createdAt: note.createdAt
      }
    });
  } catch (error) {
    console.error('Get note error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error fetching note'
    });
  }
});

router.put('/:noteId', async (req, res) => {
  try {
    const { title, content } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    const note = await Note.findOneAndUpdate(
      { _id: req.params.noteId, userId: req.session.userId },
      { title, content, lastUpdated: new Date() },
      { new: true }
    );

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Note not found'
      });
    }

    res.json({
      success: true,
      message: 'Note updated successfully',
      note: {
        id: note._id,
        title: note.title,
        content: note.content,
        lastUpdated: note.lastUpdated,
        createdAt: note.createdAt
      }
    });
  } catch (error) {
    console.error('Update note error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error updating note'
    });
  }
});

router.delete('/:noteId', async (req, res) => {
  try {
    const note = await Note.findOneAndDelete({
      _id: req.params.noteId,
      userId: req.session.userId
    });

    if (!note) {
      return res.status(404).json({
        success: false,
        message: 'Note not found'
      });
    }

    res.json({
      success: true,
      message: 'Note deleted successfully'
    });
  } catch (error) {
    console.error('Delete note error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error deleting note'
    });
  }
});

module.exports = router;