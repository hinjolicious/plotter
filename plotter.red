Red [
	Title: "Plotter Library"
	Author: "hinjolicious"
	Version: 1.0.0
	needs: 'view
]

#include %nice-range.red
#include %nice-bands.red

; Provide a clean namespace indicator
system/words/plotter-lib-loaded?: true

PLOTTER: make object! [
	; --- Configuration Sub-Object ---
	plot-config: object [
		margin: 48x40    ; left/bottom margins
		top-margin: 30   ; space for title
		right-margin: 15
		tick-length: 5
		font-size: 10
		title-size: 12
		label-size: 10
		scale-size: 8
	]

	; --- Internal Helpers (Encapsulated) ---
	min-of: func [s [series!] /local m] [m: first s foreach v s [if v < m [m: v]] m]
	max-of: func [s [series!] /local m] [m: first s foreach v s [if v > m [m: v]] m]

	make-ticks: function [min max ticks] [
		collect [
			step: (max - min) / (ticks - 1)
			repeat i ticks [keep min + (step * (i - 1))]
		]
	]

	scale-point: function [x y xr yr pa] [ 
		pa1x: pa/1/x  pa1y: pa/1/y
		pa2x: pa/2/x  pa2y: pa/2/y
		xr1: xr/1  xr2: xr/2
		yr1: yr/1  yr2: yr/2
		as-pair
			to-integer pa1x + ((x - xr1) / (xr2 - xr1) * (pa2x - pa1x))
			to-integer pa2y - ((y - yr1) / (yr2 - yr1) * (pa2y - pa1y))
	]

	marker: func [m p /local b][
		b: case [
			m = 'dot           [[circle (p) 3]]
			m = 'box           [[box (p - 3) (p + 3)]]
			m = 'triangle      [[polygon (p - 0x3) (p + -3x3) (p + 3x3)]] ; Fixed typo 'pt -> 'p
			m = 'triangle-down [[polygon (p + 0x3) (p + 3x-3) (p - 3x3)]]
			m = 'triangle-left [[polygon (p - 3x0) (p + 3x-3) (p + 3x3)]]
			m = 'triangle-right [[polygon (p + 3x0) (p + -3x3) (p - 3x3)]]
			m = 'cross         [[line (p - 3) (p + 3) line (p + 3x-3) (p + -3x3)]]
			m = 'plus          [[line (p + -4x0) (p + 4x0) line (p + 0x-4) (p + 0x4)]]
		]
		compose b
	]

	regression: function [xa ya][
		n: length? xa
		xm: ym: x2m: x3m: x4m: xym: x2ym: 0.0
		repeat i n [
			xi: xa/:i yi: ya/:i
			xm: xm + xi ym: ym + yi
			x2m: x2m + (xi * xi)
			x3m: x3m + (xi * xi * xi)
			x4m: x4m + (xi * xi * xi * xi)
			xym: xym + (xi * yi)
			x2ym: x2ym + (xi * xi * yi)
		]
		xm: xm / n ym: ym / n x2m: x2m / n x3m: x3m / n 
		x4m: x4m / n xym: xym / n x2ym: x2ym / n
		sxx: x2m - (xm * xm) sxy: xym - (xm * ym)
		sxx2: x3m - (xm * x2m) sx2x2: x4m - (x2m * x2m) sx2y: x2ym - (x2m * ym)
		denom: sxx * sx2x2 - (sxx2 * sxx2)
		b: (sxy * sx2x2 - (sx2y * sxx2)) / denom
		a: (sx2y * sxx - (sxy * sxx2)) / denom
		c: ym - (b * xm) - (a * x2m)
		reduce [a b c]
	]
	
	normal-fit: function [xa ya][
		regression xa collect [foreach y ya [
			keep log-e (y + 1)
		]]
	]	

	make-poly: func [a b c /local bd][
		bd: [a * (x ** 2) + (b * x) + c]
		bd/1: a bd/5/1: b bd/7: c
		func [x] bd
	]
	
	make-normal: func [a b c /local ctx] [
		ctx: object [
			sigma: sqrt (negate (1.0 / (2.0 * a)))
			mu: b * (sigma ** 2)
			alpha: exp (c + ((mu ** 2) / (2.0 * (sigma ** 2))))
		]
		func [x] bind [
			alpha * exp (negate ((x - mu) ** 2) / (2.0 * (sigma ** 2)))
		] ctx
	]	
	
	fitting: function [pl][
		xa: copy [] ya: copy []
		foreach [x y] pl/2 [append xa x append ya y]
		coef: regression xa ya
		f: make-poly coef/1 coef/2 coef/3
		d: collect [foreach [x y] pl/2 [keep compose [(x) (f x)]]]
		compose/deep [
			[line (rejoin [pl/1/2 " (regression)"]) (pl/1/7) none (pl/1/8)]
			[(d)]
		]
	]
	
	normal-fitting: function [pl][
		xa: copy [] ya: copy []
		foreach [x y] pl/2 [append xa x append ya y]
		coef: normal-fit xa ya
		f: make-normal coef/1 coef/2 coef/3
		d: collect [foreach [x y] pl/2 [keep compose [(x) (f x)]]]
		compose/deep [
			[line (rejoin [pl/1/2 " (regression)"]) (pl/1/7) none (pl/1/8)]
			[(d)]
		]
	]

	; --- Core Engine Implementation ---
	make-plot: function [
		canvas-size [pair!] data [block!] ttl xl yl xr yr xb yb title? x-label? y-label? x-range? y-range? x-bands? y-bands?
	][
		cfg: plot-config
		
		; shortcuts: left, bottom, top, right margins, canvas size x and y
		_lm: cfg/margin/1  _bm: cfg/margin/2  _tm: cfg/top-margin  _rm: cfg/right-margin
		_cvx: canvas-size/x  _cvy: canvas-size/y
		
		; plot area, width, height
		plot-area: reduce [as-pair _lm _tm  as-pair (_cvx - _rm) (_cvy - _bm)]
		_pw: _cvx - _lm - _rm  _ph: _cvy - _tm - _bm
		
		; x series, y series, extracted from data
		xs: extract data/1/2 2 
		ys: extract next data/1/2 2
		
		; if not specified, calculate x and y range
		unless x-range? [xr: nice-range (min-of xs) (max-of xs)]
		unless y-range? [yr: nice-range (min-of ys) (max-of ys)]
		
		; add padding to plot area 
		x-pad: (xr/2 - xr/1) * 0.025	; usefull to add space for histogram
		;y-pad: (yr/2 - yr/1) * 0.025
		xr: reduce [xr/1 - x-pad  xr/2 + x-pad]
		;yr: reduce [yr/1 - y-pad  yr/2 + y-pad]		
		
		blk: copy []
		
		; draw canvas, plot area background
		append blk compose [fill-pen white box 0x0 (canvas-size) box (plot-area/1) (plot-area/2)]
		
		; divide axes into bands and ticks nicely
		unless x-bands? [xb: nice-bands xr/1 xr/2] 
		unless y-bands? [yb: nice-bands yr/1 yr/2]
		x-ticks: make-ticks xr/1 xr/2 (xb + 1)
		y-ticks: make-ticks yr/1 yr/2 (yb + 1)
		
		; draw grid lines based on ticks
		append blk [pen 230.230.230 line-width 1]
		foreach xt x-ticks [
			pt: scale-point xt yr/1 xr yr plot-area
			append blk compose [line (as-pair pt/x plot-area/1/y) (as-pair pt/x plot-area/2/y)]
		]
		foreach yt y-ticks [
			pt: scale-point xr/1 yt xr yr plot-area
			append blk compose [line (as-pair plot-area/1/x pt/y) (as-pair plot-area/2/x pt/y)]
		]
		
		; draw axes
		append blk compose [
			pen black line-width 2
			line (as-pair plot-area/1/x plot-area/2/y) (plot-area/2)
			line (plot-area/1) (as-pair plot-area/1/x plot-area/2/y)
		
			; font for scales (below)
			line-width 1 font (make font! [size: cfg/scale-size style: 'normal])
		]
		
		; draw x axis tick marks and scales
		foreach xt x-ticks [
			pt: scale-point xt yr/1 xr yr plot-area
			_ts: cfg/scale-size  
			; scale display, should be smart enough to include fraction if necessary
			_tf: form round/to xt 0.1 ; currently not that smart
			_tw: (length? _tf) * _ts * 0.6  
			_ypos: pt/y + 5
			append blk compose [
				line (pt) (pt + 0x5) ; tick marks
				text (as-pair pt/x - (_tw / 2)  _ypos) (_tf) ; scales
			]
		]
		
		; draw y axis tick marks and scales
		; find the longest scale text
		_ysw: 0
		y-scales: collect [
			foreach yt y-ticks [
				either yt > 1000 [
					_ys: form round/to (yt / 100) 1
				][
					_ys: form round/to yt 1
				]
				if (length? _ys) > _ysw [_ysw: length? _ys]
				keep _ys
			]
		]
		
		_ysw: _ysw * cfg/scale-size * 0.6
		_xpos: _lm - _ysw - 10
		
		; draw the scales on each ticks
		foreach yt y-ticks [
			pt: scale-point xr/1 yt xr yr plot-area
			_ts: cfg/scale-size 
			either yt > 1000 [
				_tf: form round/to (yt / 1000) 0.1
				_mul: " (x 1000)"
			][
				_tf: form round/to yt 0.1
				_mul: ""
			]
			_tw: (length? _tf) * _ts * 0.6
			append blk compose [
				line (pt) (as-pair pt/x - 5 pt/y)
				text (as-pair _lm - 8 - _tw pt/y - _ts) (_tf)
			]
		]
		
		; draw title
		if title? [
			_ts: cfg/title-size _tw: (length? ttl) * _ts * 0.5
			append blk compose [
				pen black font (make font! [size: _ts style: 'normal])
				text (as-pair canvas-size/x / 2 - (_tw / 2) _tm - 3 - _ts - 10) (ttl)
			]      
		]
		
		; draw x label
		if x-label? [
			_ts: cfg/label-size _tw: (length? xl) * _ts * 0.5 _ypos: _ypos + 3 + _ts
			append blk compose [
				font (make font! [size: _ts style: 'normal])
				text (as-pair _lm + (_pw / 2) - (_tw / 2) _ypos) (xl)
			]
		]   
		
		; draw y label
		if y-label? [
			_ts: cfg/label-size _tw: (length? yl) * _ts * 0.6
			append blk compose/deep [
				font (make font! [size: cfg/font-size style: 'normal])
				push [
					translate (as-pair _xpos - 30 _tm + (_ph / 2) + (_tw / 2))
					rotate -90 text 0x0 (rejoin [yl _mul])
				]
			]
		]   
		
		; plot data 
		foreach pl data [
			pinfo: pl/1 pdata: pl/2
			ptyp: pinfo/1 pleg: pinfo/2 pcol: pinfo/3 pdot: pinfo/4 pthk: pinfo/5
			
			points: collect [foreach [x y] pdata [keep scale-point x y xr yr plot-area]]
			
			case [
				ptyp = 'scatter [ 
					append blk compose [pen (pcol) line-width (pthk) fill-pen (pcol)]
					foreach pt points [append blk marker pdot pt]
				]
				ptyp = 'line [
					append blk compose [pen (pcol) line-width (pthk) fill-pen off line (points)]
				]           
				ptyp = 'histogram [
					_hw: (points/2/x - points/1/x) * pthk / 2
					append blk compose [pen (pcol) line-width 0 fill-pen (pcol)]
					foreach pt points [
						_br: as-pair _hw (canvas-size/y - _bm - pt/y - 1)
						_tr: as-pair _hw 0
						append blk compose [box (pt - _tr) (pt + _br)]
					]
				]
			]
		]
		
		; draw legend box
		_llen: 0
		foreach pl data [if (length? pl/1/2) > _llen [_llen: length? pl/1/2]]
		_lheight: (length? data) * cfg/scale-size * 1.5
		_ltl: as-pair _lm + 5  _tm + 5
		_lbr: as-pair _ltl/x + (_llen * cfg/scale-size * 0.65) + 25  _ltl/y + _lheight + 10
		
		append blk compose/deep [
			pen 200.200.200 line-width 1 fill-pen 255.255.255.80 box (_ltl) (_lbr)
		]
		
		; draw legend markers and texts
		pt: as-pair _lm + 15 _tm + 15
		foreach pl data [
			pinfo: pl/1 ptyp: pinfo/1 pleg: pinfo/2 pcol: pinfo/3 pdot: pinfo/4 pthk: pinfo/5
			case [
				ptyp = 'scatter   [append blk compose [pen (pcol) line-width (pthk) fill-pen (pcol) (marker pdot pt)]]
				ptyp = 'line      [append blk compose [pen (pcol) line-width (pthk) fill-pen off line (pt + -5x0) (pt + 5x0)]]
				ptyp = 'histogram [append blk compose [pen (pcol) line-width 0 fill-pen (pcol) box (pt - 5) (pt + 5)]]
			]
			append blk compose [
				pen black font (make font! [size: cfg/scale-size style: 'normal])
				text (pt + 10x-8) (pleg)
			]
			pt: pt + 0x12
		]
		
		blk
	]

	; --- User-Facing Generation Interface ---
	plot: func [
		canvas-size [pair!] data [block!]
		/title ttl [string!] /x-label xl [string!] /y-label yl [string!]
		/x-range xr [block!] /y-range yr [block!] /x-bands xb /y-bands yb
		/local d
	] [
		; Handle trend fitting modifiers natively
		data: head data
		while [not tail? data] [
			d: data/1
			if d/1/6 = 'fit [insert/only next data fitting d]
			if d/1/6 = 'normal-fit [insert/only next data normal-fitting d]
			data: next data
		]
		data: head data
		
		; Pass refinements directly downward safely
		make-plot canvas-size data ttl xl yl xr yr xb yb title x-label y-label x-range y-range x-bands y-bands
	]
]