{- This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, you can
   obtain one at http://mozilla.org/MPL/2.0/.

   Copyright 2016 by Ian Mackenzie
   ian.e.mackenzie@gmail.com
-}


module OpenSolid.Frame3d
    exposing
        ( xyz
        , at
        , originPoint
        , xDirection
        , yDirection
        , zDirection
        , xAxis
        , yAxis
        , zAxis
        , xyPlane
        , yxPlane
        , yzPlane
        , zyPlane
        , zxPlane
        , xzPlane
        , xySketchPlane
        , yxSketchPlane
        , yzSketchPlane
        , zySketchPlane
        , zxSketchPlane
        , xzSketchPlane
        , flipX
        , flipY
        , flipZ
        , rotateAround
        , rotateAroundOwn
        , translateBy
        , translateAlongOwn
        , moveTo
        , mirrorAcross
        , mirrorAcrossOwn
        , relativeTo
        , placeIn
        , encode
        , decoder
        )

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder, (:=))
import OpenSolid.Core.Types exposing (..)
import OpenSolid.Point3d as Point3d
import OpenSolid.Direction3d as Direction3d
import OpenSolid.Axis3d as Axis3d


xyz : Frame3d
xyz =
    at Point3d.origin


at : Point3d -> Frame3d
at point =
    Frame3d
        { originPoint = point
        , xDirection = Direction3d.x
        , yDirection = Direction3d.y
        , zDirection = Direction3d.z
        }


originPoint : Frame3d -> Point3d
originPoint (Frame3d properties) =
    properties.originPoint


xDirection : Frame3d -> Direction3d
xDirection (Frame3d properties) =
    properties.xDirection


yDirection : Frame3d -> Direction3d
yDirection (Frame3d properties) =
    properties.yDirection


zDirection : Frame3d -> Direction3d
zDirection (Frame3d properties) =
    properties.zDirection


xAxis : Frame3d -> Axis3d
xAxis frame =
    Axis3d { originPoint = originPoint frame, direction = xDirection frame }


yAxis : Frame3d -> Axis3d
yAxis frame =
    Axis3d { originPoint = originPoint frame, direction = yDirection frame }


zAxis : Frame3d -> Axis3d
zAxis frame =
    Axis3d { originPoint = originPoint frame, direction = zDirection frame }


xyPlane : Frame3d -> Plane3d
xyPlane frame =
    Plane3d
        { originPoint = originPoint frame
        , normalDirection = zDirection frame
        }


yxPlane : Frame3d -> Plane3d
yxPlane frame =
    Plane3d
        { originPoint = originPoint frame
        , normalDirection = Direction3d.negate (zDirection frame)
        }


yzPlane : Frame3d -> Plane3d
yzPlane frame =
    Plane3d
        { originPoint = originPoint frame
        , normalDirection = xDirection frame
        }


zyPlane : Frame3d -> Plane3d
zyPlane frame =
    Plane3d
        { originPoint = originPoint frame
        , normalDirection = Direction3d.negate (xDirection frame)
        }


zxPlane : Frame3d -> Plane3d
zxPlane frame =
    Plane3d
        { originPoint = originPoint frame
        , normalDirection = yDirection frame
        }


xzPlane : Frame3d -> Plane3d
xzPlane frame =
    Plane3d
        { originPoint = originPoint frame
        , normalDirection = Direction3d.negate (yDirection frame)
        }


xySketchPlane : Frame3d -> SketchPlane3d
xySketchPlane frame =
    SketchPlane3d
        { originPoint = originPoint frame
        , xDirection = xDirection frame
        , yDirection = yDirection frame
        }


yxSketchPlane : Frame3d -> SketchPlane3d
yxSketchPlane frame =
    SketchPlane3d
        { originPoint = originPoint frame
        , xDirection = yDirection frame
        , yDirection = xDirection frame
        }


yzSketchPlane : Frame3d -> SketchPlane3d
yzSketchPlane frame =
    SketchPlane3d
        { originPoint = originPoint frame
        , xDirection = yDirection frame
        , yDirection = zDirection frame
        }


zySketchPlane : Frame3d -> SketchPlane3d
zySketchPlane frame =
    SketchPlane3d
        { originPoint = originPoint frame
        , xDirection = zDirection frame
        , yDirection = yDirection frame
        }


zxSketchPlane : Frame3d -> SketchPlane3d
zxSketchPlane frame =
    SketchPlane3d
        { originPoint = originPoint frame
        , xDirection = zDirection frame
        , yDirection = xDirection frame
        }


xzSketchPlane : Frame3d -> SketchPlane3d
xzSketchPlane frame =
    SketchPlane3d
        { originPoint = originPoint frame
        , xDirection = xDirection frame
        , yDirection = zDirection frame
        }


flipX : Frame3d -> Frame3d
flipX frame =
    Frame3d
        { originPoint = originPoint frame
        , xDirection = Direction3d.negate (xDirection frame)
        , yDirection = yDirection frame
        , zDirection = zDirection frame
        }


flipY : Frame3d -> Frame3d
flipY frame =
    Frame3d
        { originPoint = originPoint frame
        , xDirection = xDirection frame
        , yDirection = Direction3d.negate (yDirection frame)
        , zDirection = zDirection frame
        }


flipZ : Frame3d -> Frame3d
flipZ frame =
    Frame3d
        { originPoint = originPoint frame
        , xDirection = xDirection frame
        , yDirection = yDirection frame
        , zDirection = Direction3d.negate (zDirection frame)
        }


rotateAround : Axis3d -> Float -> Frame3d -> Frame3d
rotateAround axis angle =
    let
        rotatePoint =
            Point3d.rotateAround axis angle

        rotateDirection =
            Direction3d.rotateAround axis angle
    in
        \frame ->
            Frame3d
                { originPoint = rotatePoint (originPoint frame)
                , xDirection = rotateDirection (xDirection frame)
                , yDirection = rotateDirection (yDirection frame)
                , zDirection = rotateDirection (zDirection frame)
                }


rotateAroundOwn : (Frame3d -> Axis3d) -> Float -> Frame3d -> Frame3d
rotateAroundOwn axis angle frame =
    rotateAround (axis frame) angle frame


translateBy : Vector3d -> Frame3d -> Frame3d
translateBy vector frame =
    Frame3d
        { originPoint = Point3d.translateBy vector (originPoint frame)
        , xDirection = xDirection frame
        , yDirection = yDirection frame
        , zDirection = zDirection frame
        }


translateAlongOwn : (Frame3d -> Axis3d) -> Float -> Frame3d -> Frame3d
translateAlongOwn axis distance frame =
    let
        displacement =
            Direction3d.times distance (Axis3d.direction (axis frame))
    in
        translateBy displacement frame


moveTo : Point3d -> Frame3d -> Frame3d
moveTo newOrigin frame =
    Frame3d
        { originPoint = newOrigin
        , xDirection = xDirection frame
        , yDirection = yDirection frame
        , zDirection = zDirection frame
        }


mirrorAcross : Plane3d -> Frame3d -> Frame3d
mirrorAcross plane =
    let
        mirrorPoint =
            Point3d.mirrorAcross plane

        mirrorDirection =
            Direction3d.mirrorAcross plane
    in
        \frame ->
            Frame3d
                { originPoint = mirrorPoint (originPoint frame)
                , xDirection = mirrorDirection (xDirection frame)
                , yDirection = mirrorDirection (yDirection frame)
                , zDirection = mirrorDirection (zDirection frame)
                }


mirrorAcrossOwn : (Frame3d -> Plane3d) -> Frame3d -> Frame3d
mirrorAcrossOwn plane frame =
    mirrorAcross (plane frame) frame


relativeTo : Frame3d -> Frame3d -> Frame3d
relativeTo otherFrame =
    let
        relativePoint =
            Point3d.relativeTo otherFrame

        relativeDirection =
            Direction3d.relativeTo otherFrame
    in
        \frame ->
            Frame3d
                { originPoint = relativePoint (originPoint frame)
                , xDirection = relativeDirection (xDirection frame)
                , yDirection = relativeDirection (yDirection frame)
                , zDirection = relativeDirection (zDirection frame)
                }


placeIn : Frame3d -> Frame3d -> Frame3d
placeIn otherFrame =
    let
        placePoint =
            Point3d.placeIn otherFrame

        placeDirection =
            Direction3d.placeIn otherFrame
    in
        \frame ->
            Frame3d
                { originPoint = placePoint (originPoint frame)
                , xDirection = placeDirection (xDirection frame)
                , yDirection = placeDirection (yDirection frame)
                , zDirection = placeDirection (zDirection frame)
                }


{-| Encode a Frame3d as a JSON object with 'originPoint', 'xDirection',
'yDirection' and 'zDirection' fields.
-}
encode : Frame3d -> Value
encode frame =
    Encode.object
        [ ( "originPoint", Point3d.encode (originPoint frame) )
        , ( "xDirection", Direction3d.encode (xDirection frame) )
        , ( "yDirection", Direction3d.encode (yDirection frame) )
        , ( "zDirection", Direction3d.encode (zDirection frame) )
        ]


{-| Decoder for Frame3d values from JSON objects with 'originPoint',
'xDirection', 'yDirection' and 'zDirection' fields.
-}
decoder : Decoder Frame3d
decoder =
    Decode.object4
        (\originPoint xDirection yDirection zDirection ->
            Frame3d
                { originPoint = originPoint
                , xDirection = xDirection
                , yDirection = yDirection
                , zDirection = zDirection
                }
        )
        ("originPoint" := Point3d.decoder)
        ("xDirection" := Direction3d.decoder)
        ("yDirection" := Direction3d.decoder)
        ("zDirection" := Direction3d.decoder)