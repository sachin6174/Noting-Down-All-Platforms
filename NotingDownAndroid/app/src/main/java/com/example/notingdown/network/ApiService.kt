package com.example.notingdown.network

import com.example.notingdown.data.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {
    @POST("auth/login")
    suspend fun login(@Body loginRequest: LoginRequest): Response<LoginResponse>

    @POST("auth/signup")
    suspend fun signup(@Body signupRequest: SignupRequest): Response<LoginResponse>

    @POST("auth/logout")
    suspend fun logout(): Response<ApiResponse<Unit>>

    @GET("auth/session")
    suspend fun getSession(): Response<SessionResponse>

    @GET("notes")
    suspend fun getNotes(
        @Query("search") search: String? = null,
        @Query("sortBy") sortBy: String? = "lastUpdated",
        @Query("sortOrder") sortOrder: String? = "desc",
        @Query("limit") limit: Int? = 50,
        @Query("skip") skip: Int? = 0
    ): Response<NotesResponse>

    @POST("notes")
    suspend fun createNote(@Body noteRequest: NoteRequest): Response<NoteResponse>

    @GET("notes/{noteId}")
    suspend fun getNoteById(@Path("noteId") noteId: String): Response<NoteResponse>

    @PUT("notes/{noteId}")
    suspend fun updateNote(
        @Path("noteId") noteId: String,
        @Body noteRequest: NoteRequest
    ): Response<NoteResponse>

    @DELETE("notes/{noteId}")
    suspend fun deleteNote(@Path("noteId") noteId: String): Response<ApiResponse<Unit>>
}