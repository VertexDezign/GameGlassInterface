package net.vertexdezign.vdt.server

import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import javax.imageio.ImageIO
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals

/**
 * The PDA overview arrives with the map painted into the middle of a decorated border, and only the
 * middle is terrain. These pin that the border is cut off proportionally — the 4x map that exposed
 * the bug ships a 4096² image for 4096 m of world, so nothing about the pixel count says where the
 * terrain starts.
 */
class ImagePipelineTest {
  /** A [size]² image: border color everywhere, [terrain] in the middle half of each axis. */
  private fun framed(size: Int, border: Int = 0xFF102030.toInt(), terrain: Int = 0xFF40A060.toInt()): ByteArray {
    val img = BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB)
    val from = size / 4
    val until = from + size / 2
    for (y in 0 until size) {
      for (x in 0 until size) {
        img.setRGB(x, y, if (x in from until until && y in from until until) terrain else border)
      }
    }
    val out = ByteArrayOutputStream()
    ImageIO.write(img, "png", out)
    return out.toByteArray()
  }

  private fun process(bytes: ByteArray, name: String = "overview.png"): BufferedImage {
    val (png, contentType) = ImagePipeline.process(bytes, name)
    assertEquals("image/png", contentType)
    return ImageIO.read(ByteArrayInputStream(png))
  }

  @Test
  fun `keeps only the terrain half of each axis`() {
    val result = process(framed(64))

    assertEquals(32, result.width)
    assertEquals(32, result.height)
    // Every surviving pixel is terrain: a single border pixel means the crop is off.
    for (y in 0 until result.height) {
      for (x in 0 until result.width) {
        assertEquals(0xFF40A060.toInt(), result.getRGB(x, y), "border leaked at ($x, $y)")
      }
    }
  }

  @Test
  fun `crops by proportion, not by the world size the PDA declares`() {
    // The 4x map's shape: the image is no bigger than a normal map's, the world is four times as
    // wide. The old crop compared 4096 m against 4096 px, found nothing to take, and kept the border.
    assertEquals(2048, process(framed(4096)).width)
  }

  @Test
  fun `decodes a DXT1 overview and cuts its border`() {
    val dds = javaClass.getResourceAsStream("/dds/dxt1_8x8.dds")!!.readBytes()
    val full = ImagePipeline.process(dds, "full.dds").let { ImageIO.read(ByteArrayInputStream(it.first)) }

    assertEquals(4, full.width)
    assertEquals(4, full.height)
  }

  @Test
  fun `passes a non-image through untouched`() {
    val raw = byteArrayOf(1, 2, 3)
    val (bytes, contentType) = ImagePipeline.process(raw, "notes.txt")

    assertEquals("application/octet-stream", contentType)
    assertContentEquals(raw, bytes)
  }

  @Test
  fun `leaves an image with no middle to take alone`() {
    val tiny = BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB)
    val out = ByteArrayOutputStream()
    ImageIO.write(tiny, "png", out)

    val result = process(out.toByteArray())

    assertEquals(1, result.width)
    assertEquals(1, result.height)
  }
}
