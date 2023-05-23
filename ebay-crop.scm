(define (script-fu-ebay-crop image drawable rotation view export-dir)
  ; Crop the image to the current selection, if any
  (let* (
         (selection (gimp-selection-bounds image))
         (has-selection (car selection))
         (coords (cdr selection))
         (selection-x (car coords))
         (selection-y (cadr coords))
         (selection-width (- (caddr coords) selection-x))
         (selection-height (- (cadddr coords) selection-y))
        )

    (if has-selection)
      (begin
        (gimp-image-crop image selection-width selection-height selection-x selection-y)
        (gimp-selection-none image)
      )
      ()
    )

  ; Scale the image
  (let* (
        (image-width (car (gimp-image-width image)))
        (image-height (car (gimp-image-height image)))
        (longest-side (max image-width image-height))
        (resize-ratio (/ 1600 longest-side))
        (resized-width (inexact->exact (floor (* image-width resize-ratio))))
        (resized-height (inexact->exact (floor (* image-height resize-ratio))))
        (new-width (min image-width resized-width))
        (new-height (min image-height resized-height))
        )

    (gimp-image-scale image new-width new-height)
  )

  ; Rotate the image as requested, then resize the image to fit the new layers
  (if (> rotation 0)
    ; Rotation in this plugin is 0-3, whereas rotation-type in GIMP procedures
    ; is 0-2. This is because there is no 0° rotation option in the GIMP API,
    ; so whatever was provided needs to be adjusted by -1.
    (let* ((rotate-type (- rotation 1)))
        (gimp-item-transform-rotate-simple drawable rotate-type FALSE 0.0 0.0)
        (gimp-image-resize-to-layers image)
    )
    ()
  )

  ; Auto-adjust image color levels
  ; Usually this is fine, but sometimes it produces weird results and manual
  ; tuning is required. In those cases, hit undo to keep the other operations
  ; but manually set the levels.
  (gimp-drawable-levels-stretch drawable)

  ; Update the UI
  (gimp-displays-flush)

  ; Export the file
  (let* (
        (quality 0.95)
        (smoothing 0.0)
        (view-name (case view
                     ((0) "front")
                     ((1) "back")
                     ((2) "inside")
                     ((3) "manual")
                     ((4) "disk")
                   )
        )
        (filename (string-append export-dir "/" view-name ".jpg"))
        (comment "")
        (subsmp 1)
        (baseline 1)
        (restart 0)
        (dct 0)
        )

    (file-jpeg-save RUN-NONINTERACTIVE
                    image
                    drawable
                    filename
                    filename
                    quality
                    smoothing
                    1
                    1
                    comment
                    subsmp
                    baseline
                    restart
                    dct
    )

    ; There have been changes, but the idea here is to automate a
    ; heavily-repetitive task, so avoiding one more dialog which
    ; prompts for "are you sure you want to close?" when we've
    ; already exported is helpful.
    (gimp-image-clean-all image)
  )
)

(script-fu-register
  "script-fu-ebay-crop"
  "Adjust for eBay..."
  "Crop and adjust product photos for listing on ebay"
  "Sam Noedel"
  "MIT"
  "May 22, 2023"
  ""                                    ; image type
  SF-IMAGE       "Image"                0
  SF-DRAWABLE    "Drawable"             0
  SF-OPTION      "Rotation"             '("0°" "90°" "180°" "270°")
  SF-OPTION      "View"                 '("Front" "Back" "Inside" "Manual" "Disk")
  SF-DIRNAME     "Export Directory"     "/mnt/ebay/"
  )

(script-fu-menu-register "script-fu-ebay-crop" "<Image>/Image")
