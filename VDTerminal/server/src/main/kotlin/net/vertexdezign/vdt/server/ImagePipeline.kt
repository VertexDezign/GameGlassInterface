package net.vertexdezign.vdt.server

import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import javax.imageio.ImageIO

/**
 * Decode → crop the decorated surround off → PNG.
 *
 * DDS is decoded via [Dds]; PNG/JPG go through ImageIO. Non-image extensions pass through as
 * `application/octet-stream`.
 *
 * The overview image is **not** the terrain. FS25 draws the playable ground into the middle of a
 * decorated border — where a map's title art, legend and painted-on surroundings live — and the game
 * itself only ever samples the middle when it puts world coordinates on the image
 * ([TERRAIN_SCALE] / [TERRAIN_OFFSET], the `mapExtension*` constants `IngameMap:new` fixes for every
 * map). Everything the app draws over this image (ground-layer rasters, field polygons, POI and
 * vehicle markers) is normalized against the terrain, so the border has to go or none of it lines up.
 *
 * This used to be a center-crop to the PDA's declared `width`/`height`, which are the *world* size in
 * meters (`map#width` in map.xml, "Width of the world"), not pixels. It survived on a coincidence: a
 * stock 2048 m map ships a 4096² overview, so cropping to "2048" landed on exactly the half this now
 * takes by proportion. A 4x map breaks it — 4096 m of world against a 4096² image leaves nothing
 * smaller to crop to, the border stays, and every terrain-normalized overlay sits wrong over it.
 */
object ImagePipeline {
  /** Fraction of each axis the terrain occupies, centered: `IngameMap.mapExtensionScaleFactor`. */
  private const val TERRAIN_SCALE = 0.5

  /** Where the terrain starts on each axis: `IngameMap.mapExtensionOffsetX` / `OffsetZ`. */
  private const val TERRAIN_OFFSET = 0.25

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
    ImageIO.write(cropToTerrain(image), "png", out)
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

  /**
   * The centered [TERRAIN_SCALE] of [img] — the part of the overview that is actually the map.
   *
   * Purely proportional, so it holds whatever resolution the map author exported at, and it is the
   * whole crop: an image too small to take a middle out of (under two pixels on an axis) is passed
   * through rather than reduced to a sliver.
   */
  private fun cropToTerrain(img: BufferedImage): BufferedImage {
    val width = (img.width * TERRAIN_SCALE).toInt()
    val height = (img.height * TERRAIN_SCALE).toInt()
    if (width < 1 || height < 1) return img

    val left = (img.width * TERRAIN_OFFSET).toInt()
    val top = (img.height * TERRAIN_OFFSET).toInt()

    val dst = BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB)
    val g = dst.createGraphics()
    g.drawImage(
      img,
      0,
      0,
      width,
      height,
      left,
      top,
      left + width,
      top + height,
      null,
    )
    g.dispose()
    return dst
  }
}
