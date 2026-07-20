package com.example.countdown_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class CountdownWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("widget_title", "Chưa có sự kiện")
                val countdown = widgetData.getString("widget_countdown", "Mở app để cập nhật")
                
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_countdown, countdown)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
