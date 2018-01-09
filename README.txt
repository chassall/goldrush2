Gold Rush 2
C. Hassall and O. Krigolson
December, 2017    

Participants choose locations at which to dig for gold. The likelihood of finding gold at a particular location is determined by an unseen probability distribution, which shrinks with each choice.

TRIAL DATA HEADERS(.txt output)
Participant Number
Block
Trial
Reward Dist (0 = many peaks, 1 = one peak)
Map Index (1-100)
Prev. Abun. Block Performance
Prev. Sparse Block Performance
Prev. Abund. Block Exponent (scale factor to increase or decrease reward probability)
Prev. Sparse Block Exponent (scale factor to increase or decrease reward probability)
Raw X (origin in upper left of window)
Raw Y
Map X (origin in lower left of map)
Map Y
Movement Time (seconds)
Mouse Clicked? (1 if trial ended in a mouse click, 0 if speed threshold was used)
Outcome (1 = win, 0 = loss)

MOVEMENT DATA (.mat output)
Block X Trial cell array
Each cell contains a matrix with columns TIME (ms), x, y (in map coordinates: 0,0 in lower left)

MARKERS
Sparse Rewards (single peak)
1 - Block Cue
2 - Pre-movement fixation
3 - Go Cue (Beep)
4 - Response
5 - Pre-feedback fixation
6 - Rock
7 - Gold
Abundant Rewards (many peaks)
11 - Block Cue
12 - Pre-movement fixation
13 - Go Cue (Beep)
14 - Response
15 - Pre-feedback fixation
16 - Rock
17 - Gold