# not following video
# modifying code and using as guide

libs <- c(
  "giscoR", "terra", "sf", "elevatr", "png", "rayshader"
)

invisible(lapply(libs, library, character.only = T))

# europe

europe_sf <- giscoR::gisco_get_countries(
  region = "Europe",
  resolution = "3"
) |>
  sf::st_union()

plot(sf::st_geometry(europe_sf))

europe_tif <- terra::rast("western-europe-p-07f9072c11af4492.tiff")

terra::plotRGB(europe_tif)

europe_bbox <- terra::ext(europe_tif) |>
  sf::st_bbox(crs = 3857) |>
  sf::st_as_sfc(crs = 3857) |>
  sf::st_transform(crs = 4326) |>
  sf::st_intersection(europe_sf)

plot(sf::st_geometry(europe_bbox))

europe_dem <- elevatr::get_elev_raster(
  locations = europe_bbox |>
    sf::st_as_sf(),
  z = 5,
  clip = "bbox"
)

europe_dem_3857 <- europe_dem |>
  terra::rast() |>
  terra::project("EPSG:3857")

terra::plot(europe_dem_3857)

# resample
europe_resampled <- terra::resample(
  x = europe_tif,
  y = europe_dem_3857,
  method = "bilinear"
)

img_file <- "europe_modified.png"

terra::writeRaster(
  europe_resampled,
  img_file,
  overwrite = T,
  NAflag = 255
)

europe_img <- png::readPNG(img_file)

# render scene
h <- nrow(europe_dem_3857)
w <- ncol(europe_dem_3857)

europe_matrix <- rayshader::raster_to_matrix(
  europe_dem_3857
)

europe_matrix |>
  rayshader::height_shade(
    texture = colorRampPalette(c("white", "grey80"))(128)
  ) |>
  rayshader::add_overlay(
    europe_img,
    alphalayer = 1
  ) |>
  rayshader::plot_3d(
    europe_matrix,
    zscale = 17,
    solid = F,
    shadow = T,
    shadow_darkness = 1,
    background = "white",
    windowsize = c(w/5, h/5),
    zoom = .42,
    phi = 89,
    theta = 0
  )

# render
rayshader::render_highquality(
  filename = "europe_highquality.png",
  preview = T,
  interactive = F,
  light = F,
  environment_light = "air_museum_playground_4k.hdr",
  intensity_env = .75,
  rotate_env = 90,
  parallel = T,
  width = w * 1.5,
  height = h * 1.5
)

