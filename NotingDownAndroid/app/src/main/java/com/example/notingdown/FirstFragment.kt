package com.example.notingdown

import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.notingdown.adapter.NoteAdapter
import com.example.notingdown.databinding.FragmentFirstBinding
import com.example.notingdown.viewmodel.NoteViewModel
import kotlinx.coroutines.launch

/**
 * A simple [Fragment] subclass as the default destination in the navigation.
 */
class FirstFragment : Fragment() {

    private var _binding: FragmentFirstBinding? = null

    // This property is only valid between onCreateView and
    // onDestroyView.
    private val binding get() = _binding!!

    private val viewModel: NoteViewModel by viewModels()
    private lateinit var noteAdapter: NoteAdapter

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        _binding = FragmentFirstBinding.inflate(inflater, container, false)
        return binding.root

    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupRecyclerView()
        observeViewModel()
        loadNotes()
    }

    private fun setupRecyclerView() {
        noteAdapter = NoteAdapter(
            onNoteClick = { note ->
                // Handle note click - could navigate to editor
            },
            onDeleteClick = { note ->
                // Handle delete click
                lifecycleScope.launch {
                    viewModel.deleteNote(note.id)
                }
            }
        )
        
        binding.notesRecyclerView.apply {
            adapter = noteAdapter
            layoutManager = LinearLayoutManager(context)
        }
    }

    private fun observeViewModel() {
        viewModel.notes.observe(viewLifecycleOwner) { notes ->
            noteAdapter.submitList(notes)
        }
    }

    private fun loadNotes() {
        lifecycleScope.launch {
            viewModel.loadNotes()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}