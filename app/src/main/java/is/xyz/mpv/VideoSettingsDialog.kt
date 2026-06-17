package `is`.xyz.mpv

import android.view.LayoutInflater
import android.view.View
import android.widget.SeekBar
import android.widget.TextView
import `is`.xyz.mpv.databinding.DialogVideoSettingsBinding

internal class VideoSettingsDialog(private val player: MPVView) {

    private lateinit var binding: DialogVideoSettingsBinding

    fun buildView(layoutInflater: LayoutInflater): View {
        binding = DialogVideoSettingsBinding.inflate(layoutInflater)

        setupSeekBar(binding.brightnessSeekBar, binding.brightnessValue, "brightness", "Brightness")
        setupSeekBar(binding.contrastSeekBar, binding.contrastValue, "contrast", "Contrast")
        setupSeekBar(binding.gammaSeekBar, binding.gammaValue, "gamma", "Gamma")
        setupSeekBar(binding.saturationSeekBar, binding.saturationValue, "saturation", "Saturation")

        return binding.root
    }

    private fun setupSeekBar(seekBar: SeekBar, textView: TextView, property: String, label: String) {
        val initialValue = MPVLib.getPropertyInt(property) ?: 0
        seekBar.progress = initialValue + 100
        textView.text = initialValue.toString()

        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(p0: SeekBar?, progress: Int, p2: Boolean) {
                val value = progress - 100
                MPVLib.setPropertyInt(property, value)
                textView.text = value.toString()
            }

            override fun onStartTrackingTouch(p0: SeekBar?) {}
            override fun onStopTrackingTouch(p0: SeekBar?) {}
        })
    }
}
