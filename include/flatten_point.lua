-- projects a 3D point in world space into 2D coordinates in screen space.
-- assumes camera is at (0, 0, 0) and pointing at (0, 0, -1).

function flatten_point(x, y, z)
 return {round(-63.5 * (x / z) + 63.5), round(-63.5 * (y / z) + 63.5)}
end