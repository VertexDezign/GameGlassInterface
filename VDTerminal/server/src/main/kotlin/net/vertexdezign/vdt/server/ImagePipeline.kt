package net.vertexdezign.vdt.server

import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import javax.imageio.ImageIO

/**
 * Decode → PNG. DDS goes through [Dds]; PNG/JPG through ImageIO; anything else passes through as
 * `application/octet-stream`.
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
