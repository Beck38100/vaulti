package fr.vaulti.app

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private companion object {
        const val SCREEN_CHANNEL = "vaulti/screen_security"
        const val CLIPBOARD_CHANNEL = "vaulti/secure_clipboard"

        /** Identifie les copies faites par Vaulti, pour ne vider que les siennes. */
        const val CLIP_LABEL = "Vaulti"

        /** ClipDescription.EXTRA_IS_SENSITIVE, constante publique depuis l'API 33. */
        const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        setSecure(call.argument<Boolean>("enabled") ?: true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copy" -> {
                        copySensitive(call.argument<String>("text").orEmpty())
                        result.success(null)
                    }
                    "clearIfOurs" -> result.success(clearOwnClip())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Copie en marquant le contenu comme sensible : sans ce drapeau, Android 13
     * et suivants affichent le mot de passe en clair dans l'aperçu du
     * presse-papiers et les claviers le gardent dans leur historique.
     */
    private fun copySensitive(text: String) {
        val clip = ClipData.newPlainText(CLIP_LABEL, text)
        clip.description.extras = PersistableBundle().apply {
            putBoolean(EXTRA_IS_SENSITIVE, true)
        }
        clipboard().setPrimaryClip(clip)
    }

    /**
     * Vide le presse-papiers seulement s'il contient encore une copie de Vaulti,
     * reconnue à son libellé. On ne lit jamais le contenu : relire le
     * presse-papiers rempli par une autre application afficherait une
     * notification système inutilement inquiétante.
     */
    private fun clearOwnClip(): Boolean {
        val manager = clipboard()
        if (manager.primaryClipDescription?.label != CLIP_LABEL) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            manager.clearPrimaryClip()
        } else {
            manager.setPrimaryClip(ClipData.newPlainText(CLIP_LABEL, ""))
        }
        return true
    }

    private fun clipboard() =
        getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

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
