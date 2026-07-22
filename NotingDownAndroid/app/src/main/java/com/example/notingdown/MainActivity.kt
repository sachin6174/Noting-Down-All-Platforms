package com.example.notingdown

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SearchView
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.notingdown.adapter.NoteAdapter
import com.example.notingdown.data.Note
import com.example.notingdown.databinding.ActivityMainBinding
import com.example.notingdown.utils.SessionManager
import com.example.notingdown.viewmodel.NoteViewModel
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var sessionManager: SessionManager
    private lateinit var noteAdapter: NoteAdapter
    private val noteViewModel: NoteViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        sessionManager = SessionManager(this)

        if (!sessionManager.isLoggedIn()) {
            navigateToAuth()
            return
        }

        setupUI()
        setupObservers()
        loadNotes()
    }

    private fun setupUI() {
        setSupportActionBar(binding.toolbar)
        
        val user = sessionManager.getUser()
        supportActionBar?.title = "Welcome, ${user?.username ?: "User"}"

        noteAdapter = NoteAdapter(
            onNoteClick = { note -> openNoteEditor(note) },
            onDeleteClick = { note -> showDeleteConfirmation(note) }
        )

        binding.recyclerViewNotes.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = noteAdapter
        }

        binding.fab.setOnClickListener {
            openNoteEditor(null)
        }

        binding.swipeRefreshLayout.setOnRefreshListener {
            loadNotes()
        }
    }

    private fun setupObservers() {
        noteViewModel.notes.observe(this) { notes ->
            binding.swipeRefreshLayout.isRefreshing = false
            noteAdapter.submitList(notes)
            
            binding.textViewEmpty.visibility = if (notes.isEmpty()) View.VISIBLE else View.GONE
            binding.recyclerViewNotes.visibility = if (notes.isEmpty()) View.GONE else View.VISIBLE
        }

        noteViewModel.isLoading.observe(this) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }

        noteViewModel.error.observe(this) { error ->
            if (error.isNotEmpty()) {
                Snackbar.make(binding.root, error, Snackbar.LENGTH_LONG).show()
            }
        }

        noteViewModel.deleteResult.observe(this) { success ->
            if (success) {
                Snackbar.make(binding.root, "Note deleted successfully", Snackbar.LENGTH_SHORT).show()
                loadNotes()
            }
        }
    }

    private fun loadNotes() {
        lifecycleScope.launch {
            noteViewModel.loadNotes()
        }
    }

    private fun openNoteEditor(note: Note?) {
        val intent = Intent(this, NoteEditorActivity::class.java)
        note?.let { intent.putExtra("note_id", it.id) }
        startActivity(intent)
    }

    private fun showDeleteConfirmation(note: Note) {
        AlertDialog.Builder(this)
            .setTitle("Delete Note")
            .setMessage("Are you sure you want to delete \"${note.title}\"?")
            .setPositiveButton("Delete") { _, _ ->
                lifecycleScope.launch {
                    noteViewModel.deleteNote(note.id)
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    override fun onResume() {
        super.onResume()
        if (sessionManager.isLoggedIn()) {
            loadNotes()
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_main, menu)
        
        val searchItem = menu.findItem(R.id.action_search)
        val searchView = searchItem.actionView as SearchView
        
        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                query?.let { searchNotes(it) }
                return true
            }

            override fun onQueryTextChange(newText: String?): Boolean {
                if (newText.isNullOrEmpty()) {
                    loadNotes()
                } else {
                    searchNotes(newText)
                }
                return true
            }
        })

        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_logout -> {
                logout()
                true
            }
            R.id.action_refresh -> {
                loadNotes()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun searchNotes(query: String) {
        lifecycleScope.launch {
            noteViewModel.searchNotes(query)
        }
    }

    private fun logout() {
        AlertDialog.Builder(this)
            .setTitle("Logout")
            .setMessage("Are you sure you want to logout?")
            .setPositiveButton("Logout") { _, _ ->
                lifecycleScope.launch {
                    try {
                        noteViewModel.logout()
                        sessionManager.clearSession()
                        navigateToAuth()
                    } catch (e: Exception) {
                        sessionManager.clearSession()
                        navigateToAuth()
                    }
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun navigateToAuth() {
        val intent = Intent(this, AuthActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}