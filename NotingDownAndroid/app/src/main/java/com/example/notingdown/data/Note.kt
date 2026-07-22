package com.example.notingdown.data

import com.google.gson.annotations.SerializedName
import java.util.Date

data class Note(
    val id: String,
    val title: String,
    val content: String,
    @SerializedName("lastUpdated") val lastUpdated: String,
    @SerializedName("createdAt") val createdAt: String
)

data class User(
    val id: String,
    val email: String,
    val username: String
)

data class ApiResponse<T>(
    val success: Boolean,
    val message: String? = null,
    val data: T? = null
)

data class LoginRequest(
    val email: String,
    val password: String
)

data class SignupRequest(
    val email: String,
    val username: String,
    val password: String
)

data class NoteRequest(
    val title: String,
    val content: String
)

data class LoginResponse(
    val success: Boolean,
    val message: String,
    val user: User? = null
)

data class NotesResponse(
    val success: Boolean,
    val notes: List<Note>,
    val pagination: Pagination? = null
)

data class NoteResponse(
    val success: Boolean,
    val message: String,
    val note: Note? = null
)

data class Pagination(
    val limit: Int,
    val skip: Int,
    val total: Int
)

data class SessionResponse(
    val success: Boolean,
    val user: User? = null,
    val message: String? = null
)
