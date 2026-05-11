package com.example.v_player

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.view.KeyEvent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import com.ryanheise.audioservice.MediaButtonReceiver

class MusicWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                // Fetch data from HomeWidgetPlugin shared preferences
                val title = widgetData.getString("title", "Not playing")
                val artist = widgetData.getString("artist", "Unknown Artist")
                val isPlaying = widgetData.getBoolean("isPlaying", false)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_artist, artist)

                if (isPlaying) {
                    setImageViewResource(R.id.widget_btn_play_pause, R.drawable.ic_pause_widget)
                } else {
                    setImageViewResource(R.id.widget_btn_play_pause, R.drawable.ic_play_widget)
                }

                // Attach standard Media Button PendingIntents to the controls
                setOnClickPendingIntent(R.id.widget_btn_prev, buildMediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
                setOnClickPendingIntent(R.id.widget_btn_play_pause, buildMediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
                setOnClickPendingIntent(R.id.widget_btn_next, buildMediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT))
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun buildMediaButtonPendingIntent(context: Context, keyCode: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
        intent.component = ComponentName(context, MediaButtonReceiver::class.java)
        intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        
        val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        return PendingIntent.getBroadcast(context, keyCode, intent, flags)
    }
}
