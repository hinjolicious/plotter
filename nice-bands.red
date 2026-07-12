Red [
    Title: "Smart Axis Band Calculator"
    Author: "hinjolicious"
]

nice-bands: function [
	"Returns [nice-min nice-max optimal-bands]"
	smin [number!] 
	smax [number!]
][
	if smin = smax [return reduce [smin - 1 smax + 1 2]]
	
	span: smax - smin
	
	; 1. Find the raw order of magnitude base-10
	magnitude: 10.0 ** round/floor ((log-10 span) / (log-10 10.0))
	normalized: span / magnitude
	
	; 2. Pick a clean, human-friendly step multiplier (0.1, 0.2, 0.5, 1.0)
	step-factor: case [
		normalized < 1.5 [0.1]
		;normalized < 3.0 [0.2] ;produce bad step on [25 50]
		normalized < 2.5 [0.2] ;this works okay on [25 50]
		normalized < 7.0 [0.5]
		true              [1.0]
	]
	step: step-factor * magnitude

	; 3. Snap boundaries cleanly to the step multiples
	nice-min: smin ;(round/floor (smin / step)) * step
	nice-max: smax ;(round/ceiling  (smax / step)) * step

	; 4. Calculate the perfect number of bands
	bands: to-integer (round/to ((nice-max - nice-min) / step) 1)

	print ["min" smin "max" smax 
		"span" span "mag" magnitude "norm" normalized 
		"s-fac" step-factor "step" step
		"nmin" nice-min "nmax" nice-max "bands" bands]

    ; 5. Safety check: If there are too many bands (e.g., > 15), group them by doubling the step
    if bands > 20 [
        step: step * 2
        nice-min: (round/floor (data-min / step)) * step
        nice-max: (round/ceiling  (data-max / step)) * step
        bands: to-integer (round/to ((nice-max - nice-min) / step) 1)
    ]
	
	;reduce [nice-min nice-max bands]
	bands
]

comment [
print mold nice-bands 25 50
;min 25.0 max 50.0 span 25.0 mag 10.0 norm 2.5 s-fac 0.2 step 2.0 nmin 25.0 nmax 50.0 bands 13
;min 25.0 max 50.0 span 25.0 mag 10.0 norm 2.5 s-fac 0.5 step 5.0 nmin 25.0 nmax 50.0 bands 5
;== [10.0 90.0 8] 
; Range becomes 10 to 90. Step is 10. It chooses 8 bands! 
; Ticks will be: 10, 20, 30, 40, 50, 60, 70, 80, 90. Beautifully spaced.

print mold nice-bands 0.3 9.3
;== [0.0 10.0 10]
; Range becomes 0 to 10. Step is 1. It chooses 10 bands.

print mold nice-bands 1034 8932
;== [1000.0 9000.0 8]
; Step is 1000. Range is 1000 to 9000. It selects 8 elegant, high-level bands.
]