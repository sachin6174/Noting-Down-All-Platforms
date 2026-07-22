package com.example.notingdown

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.activity.OnBackPressedCallback
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.example.notingdown.databinding.ActivityNoteEditorBinding
import com.example.notingdown.viewmodel.NoteViewModel
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch

class NoteEditorActivity : AppCompatActivity() {
    private lateinit var binding: ActivityNoteEditorBinding
    private val noteViewModel: NoteViewModel by viewModels()
    private var noteId: String? = null
    private var isEditMode = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityNoteEditorBinding.inflate(layoutInflater)
        setContentView(binding.root)

        noteId = intent.getStringExtra("note_id")
        isEditMode = noteId != null

        setupUI()
        setupObservers()
        setupBackPressedCallback()
        
        if (isEditMode) {
            loadNote()
        }
    }

    private fun setupUI() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = if (isEditMode) "Edit Note" else "Create Note"
        }
    }

    private fun setupObservers() {
        noteViewModel.noteResult.observe(this) { result ->
            result.fold(
                onSuccess = { note ->
                    if (isEditMode && noteId == note.id) {
                        binding.editTextTitle.setText(note.title)
                        binding.editTextContent.setText(note.content)
                    } else {
                        Snackbar.make(binding.root, "Note saved successfully", Snackbar.LENGTH_SHORT).show()
                        finish()
                    }
                },
                onFailure = { error ->
                    Snackbar.make(binding.root, "Error: ${error.message}", Snackbar.LENGTH_LONG).show()
                }
            )
        }
    }

    private fun loadNote() {
        noteId?.let { id ->
            lifecycleScope.launch {
                noteViewModel.getNoteById(id)
            }
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_note_editor, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                onBackPressed()
                true
            }
            R.id.action_save -> {
                saveNote()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun saveNote() {
        val title = binding.editTextTitle.text.toString().trim()
        val content = binding.editTextContent.text.toString().trim()

        if (title.isEmpty()) {
            binding.editTextTitle.error = "Title is required"
            return
        }

        if (content.isEmpty()) {
            binding.editTextContent.error = "Content is required"
            return
        }

        lifecycleScope.launch {
            if (isEditMode && noteId != null) {
                noteViewModel.updateNote(noteId!!, title, content)
            } else {
                noteViewModel.createNote(title, content)
            }
        }
    }

    private fun setupBackPressedCallback() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val title = binding.editTextTitle.text.toString().trim()
                val content = binding.editTextContent.text.toString().trim()

                if (title.isNotEmpty() || content.isNotEmpty()) {
                    androidx.appcompat.app.AlertDialog.Builder(this@NoteEditorActivity)
                        .setTitle("Unsaved Changes")
                        .setMessage("You have unsaved changes. Are you sure you want to leave?")
                        .setPositiveButton("Leave") { _, _ ->
                            finish()
                        }
                        .setNegativeButton("Stay", null)
                        .show()
                } else {
                    finish()
                }
            }
        })
    }
}