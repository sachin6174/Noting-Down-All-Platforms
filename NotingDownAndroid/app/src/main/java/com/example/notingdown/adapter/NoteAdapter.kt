package com.example.notingdown.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.notingdown.data.Note
import com.example.notingdown.databinding.NoteItemBinding
import java.text.SimpleDateFormat
import java.util.*

class NoteAdapter(
    private val onNoteClick: (Note) -> Unit,
    private val onDeleteClick: (Note) -> Unit
) : ListAdapter<Note, NoteAdapter.NoteViewHolder>(NoteDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): NoteViewHolder {
        val binding = NoteItemBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return NoteViewHolder(binding)
    }

    override fun onBindViewHolder(holder: NoteViewHolder, position: Int) {
        val note = getItem(position)
        holder.bind(note)
    }

    inner class NoteViewHolder(
        private val binding: NoteItemBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(note: Note) {
            binding.apply {
                textViewTitle.text = note.title
                textViewContent.text = note.content
                
                try {
                    val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
                    val outputFormat = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
                    val date = inputFormat.parse(note.lastUpdated)
                    textViewDate.text = "Last updated: ${outputFormat.format(date ?: Date())}"
                } catch (e: Exception) {
                    textViewDate.text = "Last updated: ${note.lastUpdated}"
                }

                root.setOnClickListener { onNoteClick(note) }
                buttonDelete.setOnClickListener { onDeleteClick(note) }
            }
        }
    }

    private class NoteDiffCallback : DiffUtil.ItemCallback<Note>() {
        override fun areItemsTheSame(oldItem: Note, newItem: Note): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Note, newItem: Note): Boolean {
            return oldItem == newItem
        }
    }
}
