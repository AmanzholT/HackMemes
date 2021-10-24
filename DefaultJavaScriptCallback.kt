import android.webkit.JavascriptInterface
import com.fasterxml.jackson.databind.ObjectMapper

private const val PAGE_LOADED_EVENT = "PageLoadedEvent"
private const val ANALYTICS_EVENT = "AnalyticEvent"

internal class DefaultJavaScriptCallback(
        private val eventListener: DefaultJavaScriptEventListener,
        private val objectMapper: ObjectMapper
) {

    @JavascriptInterface
    fun handleJavaScriptEvent(json: String) {
        val eventMessage = objectMapper.readValueSafely(
                value = json,
                type = DefaultJavaScriptEventMessage::class.java
        ) ?: return

        val event = getDefaultJavaScriptEvent(eventMessage, json) ?: return

        eventListener.onJavaScriptEventReceived(event)
    }

    private fun getDefaultJavaScriptEvent(
            eventMessage: DefaultJavaScriptEventMessage,
            payloadJson: String
    ): PartsMarketplaceJavaScriptEvent? = when (eventMessage.name) {
        PAGE_LOADED_EVENT -> DefaultJavaScriptEvent.PageLoadedEvent
        ANALYTICS_EVENT -> getAnalyticsEvent(eventMessage.payload)
        else -> null
    }

    private fun getAnalyticsEvent(
            payload: DefaultJavaScriptEventMessagePayload?
    ): DefaultJavaScriptEvent.AnalyticsEvent? {
        if (payload == null) return null

        return DefaultJavaScriptEvent.AnalyticsEvent(
                eventName = payload.analyticsEventName.orEmpty(),
                eventParameters = payload.analyticsEventParameters
        )
    }
}