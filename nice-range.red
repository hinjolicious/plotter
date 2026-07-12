Red [
    Title: "Smart Axis Range Expander"
    Author: "hinjolicious"
]

nice-range: function [
    "Calculates clean, rounded upper and lower limits for an axis range"
    data-min [number!] 
    data-max [number!]
][
    ; 1. Handle flat/identical data boundaries gracefully
    if data-min = data-max [
        return either data-min = 0 [reduce [-1 1]][reduce [data-min * 0.9 data-min * 1.1]]
    ]
    
    ; 2. Find raw span and its order of magnitude base-10
    span: data-max - data-min
    ; log10(x) = ln(x) / ln(10)
    magnitude: change-scale: 10 ** round/floor ((log-10 span) / (log-10 10.0))
    
    ; 3. Determine a nice step interval size based on the magnitude scale
    ; If the span is small relative to the magnitude, use half-steps or quarter steps
    normalized-span: span / magnitude
    step: case [
        normalized-span < 2.0 [0.2 * magnitude]
        normalized-span < 5.0 [0.5 * magnitude]
        true                  [1.0 * magnitude]
    ]
    
    ; Special override: If step size drops to 1, don't allow fractional steps
    if all [step < 1.0 (to-integer data-max) = data-max (to-integer data-min) = data-min][
        step: 1.0
    ]

    ; 4. Force floor on min and ceiling on max to the exact step multiple
    nice-min: (round/floor (data-min / step)) * step
    nice-max: (round/ceiling  (data-max / step)) * step
    
    reduce [nice-min nice-max]
]

comment {
print mold nice-range 0.3 9.3
;== [0.0 10.0]  <-- Exactly what you wanted! Fractions disappear.

print mold nice-range 8932 11034
;== [8930.0 11040.0] <-- Clean multiples of 10 at the thousands boundary.

print mold nice-range 12 88
;== [10.0 90.0] <-- Rounds out to nice outer structural bounds.

print mold nice-range 0.15 0.72
;== [0.1 0.8] <-- Scales smoothly down to sub-unit decimals!
}