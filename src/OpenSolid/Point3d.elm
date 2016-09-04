{- This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, you can
   obtain one at http://mozilla.org/MPL/2.0/.

   Copyright 2016 by Ian Mackenzie
   ian.e.mackenzie@gmail.com
-}


module OpenSolid.Point3d
    exposing
        ( origin
        , midpoint
        , interpolate
        , along
        , coordinates
        , xCoordinate
        , yCoordinate
        , zCoordinate
        , vectorFrom
        , vectorTo
        , distanceFrom
        , squaredDistanceFrom
        , distanceFromAxis
        , squaredDistanceFromAxis
        , signedDistanceAlong
        , signedDistanceFrom
        , scaleAbout
        , rotateAround
        , translateBy
        , mirrorAcross
        , projectOnto
        , projectOntoAxis
        , relativeTo
        , placeIn
        , projectInto
        , placeOnto
        , encode
        , decoder
        )

{-| Various functions for creating and working with `Point3d` values. For the
examples below, assume that all OpenSolid core types have been imported using

    import OpenSolid.Core.Types exposing (..)

and all necessary modules have been imported using the following pattern:

    import OpenSolid.Point3d as Point3d

Examples use `==` to indicate that two expressions are equivalent, even if (due
to numerical roundoff) they might not be exactly equal.

# Constants

@docs origin

# Constructors

The simplest way to construct a `Point3d` value is by passing a tuple of X, Y
and Z coordinates to the `Point3d` constructor, for example
`Point2d ( 2, 1, 3 )`. But that is not the only way!

@docs midpoint, interpolate, along

# Coordinates

@docs coordinates, xCoordinate, yCoordinate, zCoordinate

# Displacement

@docs vectorFrom, vectorTo

# Distance

@docs distanceFrom, squaredDistanceFrom, distanceFromAxis, squaredDistanceFromAxis, signedDistanceAlong, signedDistanceFrom

# Transformations

@docs scaleAbout, rotateAround, translateBy, mirrorAcross, projectOnto, projectOntoAxis

# Coordinate frames

Functions for transforming points between local and global coordinates in
different coordinate frames.

@docs relativeTo, placeIn

# Sketch planes

@docs projectInto, placeOnto

# JSON serialization

@docs encode, decoder
-}

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder, (:=))
import OpenSolid.Core.Types exposing (..)
import OpenSolid.Point2d as Point2d
import OpenSolid.Vector3d as Vector3d
import OpenSolid.Direction3d as Direction3d


addTo : Point3d -> Vector3d -> Point3d
addTo =
    flip translateBy


{-| The point (0, 0, 0).

    Point3d.origin == Point3d ( 0, 0, 0 )
-}
origin : Point3d
origin =
    Point3d ( 0, 0, 0 )


{-| Construct a point halfway between two other points.

    p1 =
        Point3d ( 1, 1, 1 )

    p2 =
        Point3d ( 3, 7, 9 )

    Point3d.midpoint p1 p2 ==
        Point3d ( 2, 4, 5 )
-}
midpoint : Point3d -> Point3d -> Point3d
midpoint firstPoint secondPoint =
    interpolate firstPoint secondPoint 0.5


{-| Construct a point by interpolating between two other points based on a
parameter that ranges from zero to one.

    startPoint =
        Point3d ( 1, 1, 0 )

    endPoint =
        Point3d ( 1, 1, 8 )

    Point3d.interpolate startPoint endPoint 0.25 ==
        Point3d ( 1, 1, 2 )

Partial application may be useful:

    interpolatedPoint : Float -> Point3d
    interpolatedPoint =
        Point3d.interpolate startPoint endPoint

    List.map interpolatedPoint [ 0, 0.5, 1 ] ==
        [ Point3d ( 1, 1, 0 )
        , Point3d ( 1, 1, 4 )
        , Point3d ( 1, 1, 8 )
        ]

You can pass values less than zero or greater than one to extrapolate:

    interpolatedPoint -0.5 ==
        Point3d ( 1, 1, -4 )

    interpolatedPoint 1.25 ==
        Point3d ( 1, 1, 10 )
-}
interpolate : Point3d -> Point3d -> Float -> Point3d
interpolate startPoint endPoint =
    let
        displacement =
            vectorFrom startPoint endPoint
    in
        \t -> translateBy (Vector3d.times t displacement) startPoint


{-| Construct a point along an axis at a particular distance from the axis'
origin point.

    Point3d.along Axis3d.z 2 ==
        Point3d ( 0, 0, 2 )

Positive and negative distances are interpreted relative to the direction of the
axis:

    horizontalAxis =
        Axis3d
            { originPoint = Point2d ( 1, 1, 1 )
            , direction = Direction3d ( -1, 0, 0 )
            }

    Point3d.along horizontalAxis 3 ==
        Point3d ( -2, 1, 1 )

    Point3d.along horizontalAxis -3 ==
        Point3d ( 4, 1, 1 )
-}
along : Axis3d -> Float -> Point3d
along (Axis3d { originPoint, direction }) distance =
    translateBy (Direction3d.times distance direction) originPoint


{-| Get the coordinates of a point as a tuple.

    ( x, y, z ) =
        Point3d.coordinates point
-}
coordinates : Point3d -> ( Float, Float, Float )
coordinates (Point3d coordinates') =
    coordinates'


{-| Get the X coordinate of a point.

    Point3d.xCoordinate (Point2d ( 2, 1, 3 )) == 2
-}
xCoordinate : Point3d -> Float
xCoordinate (Point3d ( x, _, _ )) =
    x


{-| Get the Y coordinate of a point.

    Point3d.yCoordinate (Point2d ( 2, 1, 3 )) == 1
-}
yCoordinate : Point3d -> Float
yCoordinate (Point3d ( _, y, _ )) =
    y


{-| Get the Z coordinate of a point.

    Point3d.zCoordinate (Point2d ( 2, 1, 3 )) == 3
-}
zCoordinate : Point3d -> Float
zCoordinate (Point3d ( _, _, z )) =
    z


{-| Find the vector from one point to another.

    startPoint =
        Point3d ( 1, 1, 1 )

    endPoint =
        Point3d ( 4, 5, 6 )

    Point3d.vectorFrom startPoint endPoint ==
        Vector3d ( 3, 4, 5 )
-}
vectorFrom : Point3d -> Point3d -> Vector3d
vectorFrom other point =
    let
        ( x', y', z' ) =
            coordinates other

        ( x, y, z ) =
            coordinates point
    in
        Vector3d ( x - x', y - y', z - z' )


{-| Flipped version of `vectorFrom`, where the end point is given first.

    startPoint =
        Point3d ( 2, 1, 3 )

    Point2d.vectorTo Point3d.origin startPoint ==
        Vector2d ( -2, -1, -3 )
-}
vectorTo : Point3d -> Point3d -> Vector3d
vectorTo =
    flip vectorFrom


{-| Find the distance between two points.

    p1 =
        Point3d ( 1, 1, 2 )

    p2 =
        Point3d ( 2, 3, 4 )

    Point3d.distanceFrom p1 p2 == 3

Partial application can be useful:

    points =
        [ Point3d ( 3, 4, 5 )
        , Point3d ( 10, 10, 10 )
        , Point3d ( -1, 2, -3 )
        ]

    distanceFromOrigin : Point3d -> Float
    distanceFromOrigin =
        Point3d.distanceFrom Point3d.origin

    List.sortBy distanceFromOrigin points ==
        [ Point3d ( -1, 2, -3 )
        , Point3d ( 3, 4, 5 )
        , Point3d ( 10, 10, 10 )
        ]
-}
distanceFrom : Point3d -> Point3d -> Float
distanceFrom other =
    squaredDistanceFrom other >> sqrt


{-| Find the square of the distance from one point to another.
`squaredDistanceFrom` is slightly faster than `distanceFrom`, so for example

    Point3d.squaredDistanceFrom p1 p2 > tolerance * tolerance

is equivalent to but slightly more efficient than

    Point3d.distanceFrom p1 p2 > tolerance

since the latter requires a square root under the hood. In many cases, however,
the speed difference will be negligible and using `distanceFrom` is much more
readable!
-}
squaredDistanceFrom : Point3d -> Point3d -> Float
squaredDistanceFrom other =
    vectorFrom other >> Vector3d.squaredLength


{-| Find the perpendicular (nearest) distance of a point from an axis.

    point =
        Point3d ( -3, 4, 0 )

    Point3d.distanceFromAxis Axis3d.x point == 4
    Point3d.distanceFromAxis Axis3d.y point == 3
    Point3d.distanceFromAxis Axis3d.z point == 5

Note that unlike in 2D, the result is always positive (unsigned) since there is
no such thing as the left or right side of an axis in 3D.
-}
distanceFromAxis : Axis3d -> Point3d -> Float
distanceFromAxis axis =
    squaredDistanceFromAxis axis >> sqrt


{-| Find the square of the perpendicular distance of a point from an axis. As
with `distanceFrom`/`squaredDistanceFrom` this is slightly more efficient than
`distanceFromAxis` since it avoids a square root.
-}
squaredDistanceFromAxis : Axis3d -> Point3d -> Float
squaredDistanceFromAxis axis =
    let
        (Axis3d { originPoint, direction }) =
            axis

        directionVector =
            Direction3d.vector direction
    in
        vectorFrom originPoint
            >> Vector3d.crossProduct directionVector
            >> Vector3d.squaredLength


{-| Determine how far along an axis a particular point lies. Conceptually, the
point is projected perpendicularly onto the axis, and then the distance of this
projected point from the axis' origin point is measured. The result will be
positive if the projected point is ahead the axis' origin point and negative if
it is behind, with 'ahead' and 'behind' defined by the direction of the axis.

    axis =
        Axis3d
            { originPoint = Point3d ( 1, 0, 0 )
            , direction = Direction3d.x
            }

    point =
        Point3d ( 3, 3, 3 )

    Point3d.signedDistanceAlong axis point == 2
    Point3d.signedDistanceAlong axis Point3d.origin == -1
-}
signedDistanceAlong : Axis3d -> Point3d -> Float
signedDistanceAlong axis =
    let
        (Axis3d { originPoint, direction }) =
            axis
    in
        vectorFrom originPoint >> Vector3d.componentIn direction


{-| Find the perpendicular distance of a point from a plane. The result will be
positive if the point is 'above' the plane and negative if it is 'below', with
'up' defined by the normal direction of the plane.

    plane =
        Plane3d
            { originPoint = Point2d ( 1, 2, 3 )
            , normalDirection = Direction2d.y
            }

    point =
        Point3d ( 3, 3, 3 )

    Point3d.signedDistanceFrom plane point == 1
    Point3d.signedDistanceFrom plane Point3d.origin == -2

This means that flipping a plane (reversing its normal direction) will also flip
the sign of the result of this function:

    flippedPlane =
        Plane3d.flip plane

    Point3d.signedDistanceFrom flippedPlane point == -1
-}
signedDistanceFrom : Plane3d -> Point3d -> Float
signedDistanceFrom plane =
    let
        (Plane3d { originPoint, normalDirection }) =
            plane
    in
        vectorFrom originPoint >> Vector3d.componentIn normalDirection


{-| Perform a uniform scaling about the given center point. The center point is
given first and the point to transform is given last. Points will contract or
expand about the center point by the given scale. Scaling by a factor of 1 is a
no-op, and scaling by a factor of 0 collapses all points to the center point.

    centerPoint =
        Point3d ( 1, 1, 1 )

    point =
        Point3d ( 1, 2, 3 )

    Point3d.scaleAbout centerPoint 3 point ==
        Point3d ( 1, 4, 7 )

    Point3d.scaleAbout centerPoint 0.5 point ==
        Point3d ( 1, 1.5, 2 )

Do not scale by a negative scaling factor - while this may sometimes do what you
want it is confusing and error prone. Try a combination of mirror and/or
rotation operations instead.
-}
scaleAbout : Point3d -> Float -> Point3d -> Point3d
scaleAbout centerPoint scale =
    vectorFrom centerPoint >> Vector3d.times scale >> addTo centerPoint


{-| Rotate a point around an axis by a given angle (in radians).

    axis =
        Axis3d.x

    angle =
        degrees 45

    point =
        Point3d ( 3, 1, 0 )

    Point3d.rotateAround axis angle point ==
        Point3d ( 3, 0.7071, 0.7071 )

Rotation direction is given by the right-hand rule, counterclockwise about the
direction of the axis.
-}
rotateAround : Axis3d -> Float -> Point3d -> Point3d
rotateAround axis angle =
    let
        (Axis3d { originPoint, direction }) =
            axis
    in
        vectorFrom originPoint
            >> Vector3d.rotateAround axis angle
            >> addTo originPoint


{-| Translate a point by a given displacement. You can think of this as 'plus'.

    point =
        Point3d ( 3, 4, 5 )

    displacement =
        Vector3d ( 1, 2, 3 )

    Point3d.translateBy displacement point ==
        Point3d ( 4, 6, 8 )
-}
translateBy : Vector3d -> Point3d -> Point3d
translateBy vector point =
    let
        ( vx, vy, vz ) =
            Vector3d.components vector

        ( px, py, pz ) =
            coordinates point
    in
        Point3d ( px + vx, py + vy, pz + vz )


{-| Mirror a point across a plane. The result will be the same distance from the
plane but on the opposite side.

    point =
        Point3d ( 1, 2, 3 )

    -- Plane3d.xy is the plane Z=0
    Point3d.mirrorAcross Plane3d.xy point ==
        Point3d ( 1, 2, -3 )

    -- Plane3d.yz is the plane X=0
    Point3d.mirrorAcross Plane3d.yz point ==
        Point3d ( -1, 2, 3 )

The plane does not have to pass through the origin:

    -- offsetPlane is the plane Z=1
    offsetPlane =
        Plane3d.offsetBy 1 Plane3d.xy

    -- The origin point is 1 unit below the offset
    -- plane, so its mirrored copy is one unit above
    Point3d.mirrorAcross offsetPlane Point3d.origin ==
        Point3d ( 0, 0, 2 )
-}
mirrorAcross : Plane3d -> Point3d -> Point3d
mirrorAcross plane =
    let
        (Plane3d { originPoint, normalDirection }) =
            plane
    in
        vectorFrom originPoint
            >> Vector3d.mirrorAcross plane
            >> addTo originPoint


{-| Project a point perpendicularly onto a plane.

    point =
        Point3d ( 1, 2, 3 )

    Point3d.projectOnto Plane3d.xy point ==
        Point3d ( 1, 2, 0 )

    Point3d.projectOnto Plane3d.yz point ==
        Point3d ( 0, 2, 3 )

The plane does not have to pass through the origin:

    offsetPlane =
        Plane3d.offsetBy 1 Plane3d.xy

    Point3d.projectOnto offsetPlane point ==
        Point3d ( 1, 2, 1 )
-}
projectOnto : Plane3d -> Point3d -> Point3d
projectOnto plane point =
    let
        (Plane3d { originPoint, normalDirection }) =
            plane

        signedDistance =
            signedDistanceFrom plane point

        displacement =
            Direction3d.times -signedDistance normalDirection
    in
        translateBy displacement point


{-| Project a point perpendicularly onto an axis.

    point =
        Point3d ( 1, 2, 3 )

    Point3d.projectOntoAxis Axis2d.x point ==
        Point2d ( 1, 0, 0 )

    Point3d.projectOntoAxis Axis2d.y point ==
        Point2d ( 0, 2, 0 )

The axis does not have to pass through the origin:

    point =
        Point3d ( 10, 10, 10 )

    offsetVerticalAxis =
        Axis3d
            { originPoint = Point3d ( 1, 1, 1 )
            , direction = Direction3d.z
            }

    Point3d.projectOntoAxis offsetVerticalAxis point ==
        Point3d ( 1, 1, 10 )
-}
projectOntoAxis : Axis3d -> Point3d -> Point3d
projectOntoAxis axis =
    let
        (Axis3d { originPoint, direction }) =
            axis
    in
        vectorFrom originPoint
            >> Vector3d.projectOntoAxis axis
            >> addTo originPoint


{-| Take a point currently expressed in global coordinates and express it in
coordinates relative to a given frame.

    localOrigin =
        Point3d ( 1, 2, 3 )

    localFrame =
        Frame3d.moveTo localOrigin Frame3d.xyz

    Point3d.relativeTo localFrame (Point3d ( 4, 5, 6 )) ==
        Point3d ( 3, 3, 3 )

    Point3d.relativeTo localFrame (Point3d ( 1, 1, 1 )) ==
        Point3d ( 0, -1, -2 )
-}
relativeTo : Frame3d -> Point3d -> Point3d
relativeTo frame =
    let
        (Frame3d { originPoint, xDirection, yDirection, zDirection }) =
            frame
    in
        vectorFrom originPoint
            >> Vector3d.relativeTo frame
            >> (\(Vector3d components) -> Point3d components)


{-| Place a point in a given frame, considering its coordinates as being
relative to that frame and returning the corresponding point in global
coordinates. Inverse of `relativeTo`.

    localOrigin =
        Point3d ( 1, 2, 3 )

    localFrame =
        Frame3d.moveTo localOrigin Frame3d.xyz

    Point3d.placeIn localFrame (Point3d ( 3, 3, 3 )) ==
        Point3d ( 4, 5, 6 )

    Point3d.placeIn localFrame (Point3d ( 0, -1, -2 )) ==
        Point3d ( 1, 1, 1 )
-}
placeIn : Frame3d -> Point3d -> Point3d
placeIn frame =
    let
        (Frame3d { originPoint, xDirection, yDirection, zDirection }) =
            frame
    in
        coordinates >> Vector3d >> Vector3d.placeIn frame >> addTo originPoint


{-| Project a point into a given sketch plane. Conceptually, this projects the
point onto the plane and then expresses the projected point in 2D sketch
coordinates.

    point =
        Point3d ( 2, 1, 3 )

    Point3d.projectInto SketchPlane3d.xy point ==
        Point2d ( 2, 1 )

    Point3d.projectInto SketchPlane3d.yz point ==
        Point2d ( 1, 3 )

    Point3d.projectInto SketchPlane3d.zx point ==
        Point2d ( 3, 2 )
-}
projectInto : SketchPlane3d -> Point3d -> Point2d
projectInto sketchPlane =
    let
        (SketchPlane3d { originPoint, xDirection, yDirection }) =
            sketchPlane
    in
        vectorFrom originPoint
            >> Vector3d.projectInto sketchPlane
            >> (\(Vector2d components) -> Point2d components)


{-| Take a point defined in 2D coordinates within a particular sketch plane and
return the corresponding point in 3D.

    point2d =
        Point2d ( 2, 1 )

    Point3d.placeOnto SketchPlane3d.xy point2d ==
        Point3d ( 2, 1, 0 )

    Point3d.placeOnto SketchPlane3d.xz point2d ==
        Point3d ( 2, 0, 1 )

The sketch plane can have any position and orientation:

    tiltedSketchPlane =
        SketchPlane3d.xy
            |> SketchPlane3d.rotateAround Axis3d.x (degrees 45)

    Point3d.placeOnto tiltedSketchPlane point2d ==
        Point3d ( 2, 0.7071, 0.7071 )
-}
placeOnto : SketchPlane3d -> Point2d -> Point3d
placeOnto sketchPlane point =
    let
        (SketchPlane3d { originPoint, xDirection, yDirection }) =
            sketchPlane

        (Point3d ( px, py, pz )) =
            originPoint

        (Vector3d ( vx, vy, vz )) =
            Vector3d.placeOnto sketchPlane
                (Vector2d (Point2d.coordinates point))
    in
        Point3d ( px + vx, py + vy, pz + vz )


{-| Encode a Point3d as a JSON object with 'x', 'y' and 'z' fields.
-}
encode : Point3d -> Value
encode point =
    Encode.object
        [ ( "x", Encode.float (xCoordinate point) )
        , ( "y", Encode.float (yCoordinate point) )
        , ( "z", Encode.float (zCoordinate point) )
        ]


{-| Decoder for Point3d values from JSON objects with 'x', 'y' and 'z' fields.
-}
decoder : Decoder Point3d
decoder =
    Decode.object3 (\x y z -> Point3d ( x, y, z ))
        ("x" := Decode.float)
        ("y" := Decode.float)
        ("z" := Decode.float)