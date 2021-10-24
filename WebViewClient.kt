import android.graphics.Bitmap
import android.webkit.WebView
import android.webkit.WebViewClient

internal class DefaultWebViewClient(
        private val callback: DefaultWebContract.WebViewClientCallback,
        private val acceptableHostList: List<String>
) : WebViewClient() {

    private var currentUrl: String? = null
    private var isError = false
    private var errorCode: Int = 0
    private var isClearHistoryNeeded = false

    override fun shouldOverrideUrlLoading(
            view: WebView,
            url: String?
    ): Boolean {
        if (url == currentUrl) {
            view.goBack()

            return true
        }
        if (isAcceptableUrl(url)) {
            view.loadUrl(url!!)
            currentUrl = url

            return false
        }
        callback.onOpenInBrowser(url.orEmpty())

        return true
    }

    override fun onPageStarted(
            view: WebView?,
            url: String?,
            favicon: Bitmap?
    ) {
        super.onPageStarted(view, url, favicon)
        isError = false
        callback.onPageLoadStarted()
    }

    override fun onReceivedError(
            view: WebView?,
            errorCode: Int,
            description: String?,
            failingUrl: String?
    ) {
        super.onReceivedError(view, errorCode, description, failingUrl)
        this.isError = true
        this.errorCode = errorCode
    }

    override fun onPageFinished(
            view: WebView?,
            url: String?
    ) {
        if (isClearHistoryNeeded) {
            view?.clearHistory()
            isClearHistoryNeeded = false
        }
        if (isError) {
            callback.onPageLoadFailed(errorCode)
        } else {
            callback.onPageLoaded()
        }
    }

    fun onClearHistoryNeeded() {
        isClearHistoryNeeded = true
    }

    private fun isAcceptableUrl(url: String?): Boolean {
        if (url == null) return false

        acceptableHostList.forEach {
            if (url.contains(it)) return true
        }

        return false
    }
}