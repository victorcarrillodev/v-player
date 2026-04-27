package com.example.v_player

import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.util.Size

class MainActivity : AudioServiceActivity() {

    private val CHANNEL = "com.example.v_player/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "querySongs" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val songs = querySongs()
                            withContext(Dispatchers.Main) {
                                result.success(songs)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ERROR", e.message, null)
                            }
                        }
                    }
                }
                "queryArtwork" -> {
                    val songId = call.argument<Int>("id") ?: run {
                        result.error("INVALID_ARGS", "Missing id", null)
                        return@setMethodCallHandler
                    }
                    val uri = call.argument<String>("uri")
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val artwork = getArtwork(songId.toLong(), uri)
                            withContext(Dispatchers.Main) {
                                result.success(artwork)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun querySongs(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()

        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} > 30000"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val cursor = contentResolver.query(
            collection,
            projection,
            selection,
            null,
            sortOrder
        )

        cursor?.use { c ->
            val idColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durationColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataColumn = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

            while (c.moveToNext()) {
                val id = c.getLong(idColumn)
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                )
                songs.add(
                    mapOf(
                        "id" to id.toInt(),
                        "title" to (c.getString(titleColumn) ?: "Unknown"),
                        "artist" to (c.getString(artistColumn) ?: "Unknown Artist"),
                        "album" to (c.getString(albumColumn) ?: "Unknown Album"),
                        "albumId" to c.getLong(albumIdColumn).toInt(),
                        "duration" to c.getLong(durationColumn).toInt(),
                        "uri" to contentUri.toString(),
                        "data" to (c.getString(dataColumn) ?: ""),
                    )
                )
            }
        }

        return songs
    }

    private fun getArtwork(songId: Long, songUri: String?): ByteArray? {
        // Fast path for Android 10+ using ContentResolver.loadThumbnail
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
                val bitmap = contentResolver.loadThumbnail(uri, Size(300, 300), null)
                val out = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                return out.toByteArray()
            } catch (_: Exception) {}
        }

        // Try album art from MediaStore
        try {
            val albumArtUri = Uri.parse("content://media/external/audio/albumart")
            val uri = ContentUris.withAppendedId(albumArtUri, songId)
            contentResolver.openInputStream(uri)?.use { stream ->
                val bitmap = BitmapFactory.decodeStream(stream)
                if (bitmap != null) {
                    val out = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    return out.toByteArray()
                }
            }
        } catch (_: Exception) {}

        // Fallback: extracting from file using MediaMetadataRetriever (Slowest)
        if (!songUri.isNullOrEmpty()) {
            try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(applicationContext, Uri.parse(songUri))
                val embeddedPicture = retriever.embeddedPicture
                retriever.release()
                if (embeddedPicture != null) {
                    return embeddedPicture
                }
            } catch (_: Exception) {}
        }

        return null
    }
}
