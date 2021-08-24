breed [citizens citizen]
breed [cops cop]
breed [criminals criminal]
citizens-own [safe? oppressed? citizen-life-span]
cops-own [cop-life-span]
criminals-own [jail-time jailed? criminal-life-span]

to setup
  clear-all
  setup-people
  setup-jail
  reset-ticks
end


to go
  move-people
  tick
  ifelse (count criminals = 0)
  [user-message (word "There are no more criminals.") stop]
  [ifelse (count cops = 0 )
    [user-message (word "The world belongs to criminals.") stop]
    [ifelse (count citizens < 20)
      [user-message (word "The Police did a bad job.") stop]
      [if (ticks > 2000) [stop]
      ]
    ]
  ]
end


to setup-jail
  if jail? = true [
    ask patches with [pxcor > 8 and pycor > 8] [set pcolor violet]
  ]
end


to setup-people
  create-citizens 1000                                            ; We create each time 1000 citizens
  ask citizens [
    setxy random-xcor random-ycor
    set citizen-life-span random 100                              ; Each citizen is born with a randomly selected life expectancy
    let oppression random 100
    let safety random 100

    ifelse (oppression < Policemen-density)
    [set oppressed? true
      set shape "face sad"]
    [set oppressed? false
      set shape "face happy"]

    ifelse (safety < Criminals-density)
    [set safe? false
      set color red]
    [set safe? true
      set color green]
  ]

  create-cops round(Policemen-density * 0.01 * count citizens)
  ask cops [
    setxy random-xcor random-ycor
    set color blue
    set shape "person"
    set cop-life-span random 100                                  ; Each policeman is born with a randomly selected life expectancy
  ]

  create-criminals round(Criminals-density * 0.01 * count citizens)
  ask criminals [
    setxy random-xcor random-ycor
    set color yellow
    set shape "person"
    set jailed? false
    set jail-time 0                                               ; Initiate a jailing time
    set criminal-life-span random 100                             ; Same as citizens and policeman
  ]
end


to move-people
  ask citizens [
    right random 360
    forward 1

    if (count criminals with [jailed? = false] in-radius 4 = 0) [
      set safe? true
      set color green
    ]

    if (count cops in-radius 4 = 0) [
      set oppressed? false
      set shape "face happy"
    ]

    if (count criminals with [jailed? = false] in-radius 1 > count citizens in-radius 1) [
      ifelse (random 30 > citizen-life-span)                      ; Condition for a criminal to have murdered a citizen
      [die
        ask citizens in-radius 4 [
          set safe? false
          set color red
        ]
      ]
      [ask citizens in-radius 2 [
        set safe? false
        set color red
        ]
      ]
    ]

    if (count cops in-radius 1 > count citizens in-radius 1) [
      ifelse (random 100 > 98)                                   ; Condition for a police blunder
      [die
        ask citizens in-radius 4 [
          set oppressed? true
          set shape "face sad"
          set safe? false
          set color red
        ]
      ]
      [ask citizens in-radius 2 [
        set oppressed? true
        set shape "face sad"
        set safe? true
        set color green
        ]
      ]
    ]
  ]

  ask cops [
    right random 360
    forward 1
    if (count criminals with [jailed? = false] in-radius 1 > count cops in-radius 1) [
      ifelse (random 100 > cop-life-span)                         ; Condition for a criminal committing a policeman murder
      [die
        ask citizens in-radius 4 [
          set oppressed? false
          set shape "face happy"                                 ; When a policeman dies, we must paradoxically state that the citizens feel less oppression from the police.
          set safe? false
          set color red]
      ]
      [ask citizens in-radius 2 [
        set oppressed? false
        set shape "face happy"
        set safe? false
        set color red]
      ]
    ]
  ]

  ask criminals [
    if (jail? = true) [
      if (jailed? = true) [
        ifelse (jail-size < Jail-max-capacity)                      ; The prison becomes inaccessible if there are more than 100 prisoners
        [set xcor (random 4) + 11
          set ycor (random 4) + 11
          set color white]                                          ; The inmates change color when they are in prison
        [setxy random-xcor random-ycor
          set jailed? false                                         ; Criminals are released if the prison is full
          set color yellow
          ask citizens in-radius 2 [                                ; Citizens who see an inmate leave do not feel safe
            set safe? false
            set color red]
        ]
      ]
      right random 360
      forward 1
      if ([jail?] of patch-here = true) [
        right 180
        forward 3
        ask citizens in-radius 1 [
          set oppressed? true                                        ; the citizens who pass through the prison feel oppressed by the symbo-
          set shape "face sad"                                       ; -lism of the government institution and not reassured by the concentra-
          set safe? false                                            ; -tion of prisoners at the same point
          set color red
        ]
      ]
      check-status

      if (jailed? = false) [
        if (count cops in-radius 1 > count criminals with [jailed? = false] in-radius 1) [
          ifelse (random 50 > criminal-life-span)                    ; Condition for policemen committing a criminal murder
          [die
            ask citizens in-radius 2 [
              set oppressed? true
              set shape "face sad"
              set safe? true
              set color green
            ]
          ]
          [set jailed? true
            ask citizens in-radius 2 [
              set oppressed? false
              set shape "face happy"
              set safe? true
              set color green
            ]
          ]
        ]
      ]
    ]

    if (jail? = false) [
      right random 360
      forward 1
      if (count cops in-radius 1 > count criminals in-radius 1) [
        ifelse (random 50 > criminal-life-span)                     ; Condition for policemen committing a criminal murder
        [die
          ask citizens in-radius 2 [
            set oppressed? true
            set shape "face sad"
            set safe? true
            set color green
          ]
        ]
        [ask citizens in-radius 2 [
          set oppressed? true
          set shape "face sad"
          set safe? false
          set color red
          ]
        ]
      ]
    ]
  ]
end


to check-status
  ask criminals [
    if (jailed? = true) and (jail? = true) [
      set jail-time jail-time + 1
      set criminal-life-span criminal-life-span - 1                     ; Criminals lose years of life in prison
      if (jail-time > random 50 and criminal-life-span > random 50) [   ; Condition of release of prisoners
        set jailed? false
        setxy random-xcor random-ycor
        set color yellow
        set jail-time 0
        ask citizens in-radius 2 [                                      ; The citizens who see an inmate leave do not feel safe
            set safe? false
            set color red]
      ]
    ]
  ]
end


to-report jail-size
  report (count criminals with [xcor > 10 and ycor > 10 and color = white])
end


; Copyright 2021 Raphaël ADAMCZYK.
@#$#@#$#@
GRAPHICS-WINDOW
886
10
1478
603
-1
-1
17.7
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
69
20
132
53
setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
144
21
207
54
go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
0

SLIDER
42
78
227
111
Policemen-density
Policemen-density
0
50
15.0
1
1
%
HORIZONTAL

SLIDER
42
129
227
162
Criminals-density
Criminals-density
0
50
10.0
1
1
%
HORIZONTAL

MONITOR
50
303
127
348
Safe
count citizens with [color = green]
17
1
11

PLOT
273
11
870
603
Evolution
time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Safe" 1.0 0 -13840069 true "" "plot (count citizens with [color = green])"
"Oppressed" 1.0 0 -955883 true "" "plot (count citizens with [shape = \"face sad\"])"
"Policemen Died" 1.0 0 -13345367 true "" "plot (Policemen-density * 10 - count cops)"
"Criminals Died" 1.0 0 -6459832 true "" "plot (Criminals-density * 10 - count criminals)"
"Jailed" 1.0 0 -7500403 true "" "plot jail-size"
"Citizens Died" 1.0 0 -5825686 true "" "plot (1000 - count citizens)"

MONITOR
141
304
218
349
Oppressed
count citizens with [shape = \"face sad\"]
17
1
11

MONITOR
139
424
243
469
Policemen Died
Policemen-density * 10 - count cops
17
1
11

MONITOR
22
488
123
533
Criminals Died
Criminals-density * 10 - count criminals
17
1
11

MONITOR
140
489
243
534
Jailed
jail-size
17
1
11

MONITOR
23
424
122
469
Citizens Died
1000 - count citizens
17
1
11

SWITCH
90
188
180
221
Jail?
Jail?
1
1
-1000

SLIDER
47
241
219
274
Jail-max-capacity
Jail-max-capacity
50
500
100.0
10
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

 "A people willing to sacrifice a little liberty for a little security deserve neither, and eventually lose both" is an apocryphal quote attributed to Benjamin Franklin, politician, scientist and founding father of the United States.
The popularity of this phrase, although distorted from its real meaning at the time, can be explained in part by its use by U.S. President Franklin Roosevelt in his Four Freedoms speech in January 1941, and then by philosopher and economist Friedrich Hayek in 1944 in his manifesto entitled The Road to Serfdom, where he denounced interventionism as a form of totalitarianism.

 So I was inspired by this quote to try to verify F. Hayek's assumptions in a very basic way. This project models the feeling of a population facing a police state, reacting in a Manichean way to two situations: either a feeling of oppression if, mainly, the presence of the police is too concentrated in the same place, or a feeling of security if the population observes that the police are doing their job and randomly arresting the criminals. 


## HOW IT WORKS

 At the beginning of each experiment, 1000 citizens are created.
The density of policemen and criminals are percentages according to the number of citizens, modifiable in the interface.
The density of each citizen cannot exceed 50% of the citizen population to ensure a certain plausibility of the experiment.

 Each citizen is born with a life expectancy (CITIZEN-LIFE-SPAN), a feeling of oppression (OPPRESSION) and a feeling of security (SAFETY), randomly assigned.
Depending on the number of police officers and criminals assigned at the beginning of each experiment, this defines from the start a general state of the population's feeling of oppression and security.

 The citizens who feel safe are in green (and therefore red in the opposite case)
Those who do not feel oppressed have a "happy" face ("sad" in the oppressed case).

 Each policeman (in blue) is born with a randomly assigned life expectancy (COP-LIFE-SPAN).
Each criminal (in yellow) is born with a randomly assigned life expectancy (CRIMINAL-LIFE-SPAN), a negative prisoner status (JAILED?), and a prison time (JAIL-TIME) set to zero.

 Once the experiment is triggered, at each move, we will examine whether, for example, the number of citizens present on the same radius is lower or not than the number of criminals present on the same radius. In the affirmative case, we then examine the chances of survival of the agent in question compared to a random number: there can then be potentially murder of the citizen in question by criminals (but also by policemen (police blunders)). 
 The risks of a murder are always decided randomly in relation to the life expectancy of the agent in question.
 In any case, this creates feelings of insecurity and/or oppression among the surrounding citizens. The feelings will spread more widely if an agent has been killed.

 The same rules apply between police officers and criminals, both classes of agents always having the possibility of murder (only the citizens remain without any real defense).  This will always induce reactions of insecurity and/or oppression among the surrounding citizens, witnessing potential murders or observing a high concentration of criminals and policemen in the same place.
 
 The JAIL? cursor in the interface allows to create a prison (violet square) within the population.  This induces new behaviors in the police and consequently in the citizens:
All citizens passing by the prison will feel insecure and oppressed by the symbol of the government institution.
 If the police outnumber the criminals, and if the life expectancy of a criminal is greater than a random number, then the criminal does not die but goes to prison (JAILED ? is then true), provided that the prison is not full (JAIL-SIZE condition). Otherwise he is released among the citizens (the feeling of insecurity then increases among the citizens seeing him).
 When the prisoner (in white) is in prison, his imprisonment time (JAIL-TIME) is incremented by one each turn. His life expectancy (CRIMINAL-LIFE-SPAN) is decremented by one each turn. 
 The prisoner will only be released if his life expectancy and time in prison are greater than a random number. When the inmate is released, the feeling of insecurity increases among the citizesn who see him.


## HOW TO USE IT

 Use the sliders to select the initial parameters of the model.

 POLICEMEN- DENSITY and CRIMINALS-DENSITY determine respectively the density of policemen and criminals in the world, according to the number of citizens (the number of citizens is always 1000 at the beginning).

 JAIL? allows the creation of a prison (purple square) and generates new behaviors for citizens and policemen.
 If JAIL? is enabled, select the maximum capacity of the prison to receive inmates with JAIL-MAX-CAPACITY (minimum of 50 inmates).
 
 Click on SETUP to initialize the filling.

 Click on GO to start the simulation.

 The color of the citizens shows their level of security. Green means feeling safe, red means feeling unsafe. This color changes throughout the execution of a model and its number, displayed in real time in the SAFE monitor, can also be visualized on the graph during the experiment.

 The appearance of the citizens shows their level of oppression. "Happy" indicates a feeling of freedom, "Sad" indicates a feeling of oppression by the police. This shape is made to change throughout the execution of a model and its number, displayed in real time in the OPPRESSED monitor, can also be visualized on the graph in the duration of the experiment.

 The number of murdered citizens, murdered policemen and murdered or imprisoned criminals are also visible in real time on their respective monitors and on the graph during the experiment.

## THINGS TO NOTICE

 After a while, the number of murdered police officers and citizens stagnates, while the number of murdered citizens rises relatively quickly.

 Feelings of oppression and safety eventually increase at the same rate.

 No matter how many police officers there are, as long as they outnumber the criminals, the feelings of oppression among citizens will always end up being high.


## THINGS TO TRY

 Observe how the police are able to turn things around when they are outnumbered with and without the prison option.

 Test cases of equal density.

 Always adjust the number of police very close to the number of criminals to try to get a relative majority of non-oppressed and a relative majority of secure.

 Modifying the jail maximum capacity.


## EXTENDING THE MODEL

Create a coefficient of arrest by the police of criminals and citizens.

Decrease the life expectancy of police officers with each round.

Modify the random numbers that condition the killing of any officer.


## NETLOGO FEATURES

The very low probability of a police officer accidentally killing a citizen and yet when most prisoners are either in jail or dead, the number of dead citizens continues to rise relatively quickly 


## RELATED MODELS

Rebellion (Copyright 2004 Uri Wilensky) in the folder "Social Science".

## CREDITS AND REFERENCES

Copyright 2021 Raphaël ADAMCZYK.

This model was created within the framework of the Agent Based Modelling project, via the course offered by Data Science Tech Institute (France)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count citizens with [color = green]</metric>
    <metric>count citizens with [shape = "face happy"]</metric>
    <metric>1000 - count citizens</metric>
    <enumeratedValueSet variable="Policemen-density">
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jail-max-capacity">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Criminals-density">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jail?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
