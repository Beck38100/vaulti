package fr.vaulti.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val CHANNEL = "vaulti/screen_security"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Protégé dès le démarrage : la fenêtre est marquée sécurisée avant même
        // que Flutter ne s'initialise, pour qu'aucune image du coffre ne puisse
        // être capturée entre-temps.
        setSecure(true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        setSecure(call.argument<Boolean>("enabled") ?: true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * FLAG_SECURE interdit les captures d'écran et masque le contenu dans
     * l'aperçu des applications récentes, qu'Android enregistre autrement
     * sur le disque.
     */
    private fun setSecure(enabled: Boolean) {
        if (enabled) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
