package com.antigravity.repeating_todo.repeating_todo_tasks

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.antigravity.repeating_todo.repeating_todo_tasks.R

class RepeatingTaskWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            // 1. Read SharedPreferences stored by Flutter
            // Flutter saves shared preferences with name "FlutterSharedPreferences" and keys prefixed with "flutter."
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val todayTasksSet = prefs.getStringSet("flutter.widget_today_tasks", null)

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            if (todayTasksSet != null && todayTasksSet.isNotEmpty()) {
                val tasksList = todayTasksSet.toList()
                
                // Hide empty state
                views.setViewVisibility(R.id.widget_empty_state, View.GONE)

                // Render first 3 tasks
                if (tasksList.size >= 1) {
                    views.setViewVisibility(R.id.task_item_1, View.VISIBLE)
                    views.setTextViewText(R.id.task_item_1, "• " + tasksList[0])
                } else {
                    views.setViewVisibility(R.id.task_item_1, View.GONE)
                }

                if (tasksList.size >= 2) {
                    views.setViewVisibility(R.id.task_item_2, View.VISIBLE)
                    views.setTextViewText(R.id.task_item_2, "• " + tasksList[1])
                } else {
                    views.setViewVisibility(R.id.task_item_2, View.GONE)
                }

                if (tasksList.size >= 3) {
                    views.setViewVisibility(R.id.task_item_3, View.VISIBLE)
                    views.setTextViewText(R.id.task_item_3, "• " + tasksList[2])
                } else {
                    views.setViewVisibility(R.id.task_item_3, View.GONE)
                }
            } else {
                // Show empty state, hide items
                views.setViewVisibility(R.id.widget_empty_state, View.VISIBLE)
                views.setViewVisibility(R.id.task_item_1, View.GONE)
                views.setViewVisibility(R.id.task_item_2, View.GONE)
                views.setViewVisibility(R.id.task_item_3, View.GONE)
            }

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
