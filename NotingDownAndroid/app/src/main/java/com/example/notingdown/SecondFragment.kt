package com.example.notingdown

import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import com.example.notingdown.databinding.FragmentSecondBinding
import com.example.notingdown.viewmodel.NoteViewModel
import com.google.android.material.snackbar.Snackbar
import kotlinx.coroutines.launch

/**
 * A simple [Fragment] subclass as the second destination in the navigation.
 */
class SecondFragment : Fragment() {

    private var _binding: FragmentSecondBinding? = null

    // This property is only valid between onCreateView and
    // onDestroyView.
    private val binding get() = _binding!!

    private val viewModel: NoteViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        _binding = FragmentSecondBinding.inflate(inflater, container, false)
        return binding.root

    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupObservers()

        binding.buttonSave.setOnClickListener {
            saveNote()
        }
    }

    private fun setupObservers() {
        viewModel.noteResult.observe(viewLifecycleOwner) { result ->
            result.fold(
                onSuccess = { note ->
                    Snackbar.make(binding.root, "Note saved successfully", Snackbar.LENGTH_SHORT).show()
                    findNavController().navigateUp()
                },
                onFailure = { error ->
                    Snackbar.make(binding.root, "Error: ${error.message}", Snackbar.LENGTH_LONG).show()
                }
            )
        }
    }

    private fun saveNote() {
        val title = binding.editNoteTitle.text.toString().trim()
        val content = binding.editNoteContent.text.toString().trim()
        
        if (title.isEmpty()) {
            binding.editNoteTitle.error = "Title is required"
            return
        }
        
        if (content.isEmpty()) {
            binding.editNoteContent.error = "Content is required"
            return
        }

        lifecycleScope.launch {
            viewModel.createNote(title, content)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}