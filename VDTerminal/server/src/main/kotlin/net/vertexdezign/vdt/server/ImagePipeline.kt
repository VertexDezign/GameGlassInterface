package net.vertexdezign.vdt.server

import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import javax.imageio.ImageIO

/**
 * Decode → PNG. DDS goes through [Dds]; PNG/JPG through ImageIO; anything else passes through as
 * `application/octet-stream`.
 *
 * The overview is served **whole**, decorated border and all, because the border is worth drawing:
 * FS25 paints the map's title art and surrounding scenery around the playable ground, and the game's
 * own map screen shows all of it. What it is *not* is the terrain — the terrain is the middle half of
 * each axis (`IngameMap:new`'s `mapExtensionScaleFactor` 0.5 and `mapExtensionOffsetX/Z` 0.25) — so
 * the app places this image across `MapOverview.SPAN` of its normalized terrain frame rather than
 * over `[0,1]`, and the ground-layer rasters that do cover exactly the terrain sit on top of it.
 *
 * This briefly cropped the border off instead, which is the same fact answered the other way: cut it
 * out here, and a panned or zoomed-out map ends in a hard square edge against the panel background.
 * Placing it is better than cutting it, and it keeps the decision in the one place that knows how
 * much of the box is on screen.
 *
 * The crop before *that* was to the PDA's declared `width`/`height`, which are the world in meters
 * and not pixels at all — see [net.vertexdezign.vdt.model.Pda].
 */
object ImagePipeline {
  fun process(data: ByteArray, filename: String): Pair<ByteArray, String> {
    val ext = filename.substringAfterLast('.', "").lowercase()

    val image: BufferedImage =
      when (ext) {
        "dds" -> {
          toBufferedImage(Dds.decode(data))
        }

        "png", "jpg", "jpeg" -> {
          ImageIO.read(ByteArrayInputStream(data)) ?: error("failed to decode $ext")
        }

        else -> {
          return data to "application/octet-stream"
        }
      }

    val out = ByteArrayOutputStream()
    ImageIO.write(image, "png", out)
    return out.toByteArray() to "image/png"
  }

  private fun toBufferedImage(decoded: DecodedImage): BufferedImage {
    val img = BufferedImage(decoded.width, decoded.height, BufferedImage.TYPE_INT_ARGB)
    val rgba = decoded.rgba
    val pixels = IntArray(decoded.width * decoded.height)
    for (i in pixels.indices) {
      val o = i * 4
      val r = rgba[o].toInt() and 0xFF
      val g = rgba[o + 1].toInt() and 0xFF
      val b = rgba[o + 2].toInt() and 0xFF
      val a = rgba[o + 3].toInt() and 0xFF
      pixels[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
    }
    img.setRGB(0, 0, decoded.width, decoded.height, pixels, 0, decoded.width)
    return img
  }
}
