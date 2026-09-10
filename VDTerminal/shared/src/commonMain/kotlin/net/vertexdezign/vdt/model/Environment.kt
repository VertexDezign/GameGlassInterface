package net.vertexdezign.vdt.model

import kotlinx.serialization.Serializable

@Serializable
data class Environment(
  val date: String? = null,
  val time: String? = null,
  val weather: Weather? = null,
  val pda: Pda? = null,
)

@Serializable
data class Weather(val temperature: Temperature? = null)

@Serializable
data class Temperature(val min: Int = 0, val max: Int = 0, val current: Int = 0, val unit: String = "")

/**
 * PDA / map data. `filename`/`width`/`height` are absent when the mod has no PDA reference, so they
 * are optional.
 *
 * [width] and [height] are the *world* in meters — map.xml's `map#width`, which the engine documents
 * as "Width of the world" — not the pixel size of [filename], and they duplicate
 * [MapData.terrainSize]. They are nobody's input: the overview image is cropped by proportion (see
 * the server's `ImagePipeline`), because on a 4x map these read 4096 next to a 4096-pixel image and
 * agreeing means nothing.
 */
@Serializable
data class Pda(
  val filename: String? = null,
  val width: Int? = null,
  val height: Int? = null,
  val player: Player? = null,
)

/**
 * The map marker's subject: on foot the player, in a vehicle the vehicle it drives. [heading] uses
 * the same compass convention as the vehicle's `Gps.heading`, so the marker reads the same in either
 * mode.
 */
@Serializable
data class Player(
  val posX: Float = 0f,
  val posZ: Float = 0f,
  val heading: Int = 0,
  val headingUnit: String = "",
  /**
   * The local player's farm id; null while spectating. Joined against [MapField.ownerFarmId] /
   * [MapPoi.ownerFarmId] to tell own fields and POIs from other farms'.
   */
  val farmId: Int? = null,
)
