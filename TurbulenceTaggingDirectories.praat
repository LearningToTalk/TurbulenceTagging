# TurbulenceTaggingDirectories.praat

# Script to set the local filesystem constants separately, so that a new Turbulence Tagger 
# does not need to edit the main TurbulenceTagging.praat script to customize these.  

# Author: Mary E. Beckman
# Date: 25 October 2013

# Local filesystem constants.

# The directory from where segmentation TextGrids are read into the praat Object Window.
segmentDirectory$  = "/LearningToTalk/Tier2/DataAnalysis/RealWordRep/TimePoint1/Segmentation/SegmentedFiles/"

# The directory from where audio files are read into the praat Object Window.
audioDirectory$    = "/LearningToTalk/Tier2/DataAnalysis/RealWordRep/TimePoint1/Recordings"

# The directory from where word list tables are read into the praat Object Window.
wordListDirectory$ = "/LearningToTalk/Tier2/DataAnalysis/RealWordRep/TimePoint1/WordLists"

# The directory from where turbulence tagging logs are read into the praat Object Window.
tagLogDirectory$   = "/LearningToTalk/Tier2/DataAnalysis/RealWordRep/TimePoint1/TurbulenceTagging/TagLogDirectory"

# The directory to where turbulence tagged TextGrids are written from the praat Object Window.
taggingDirectory$  =  "/LearningToTalk/Tier2/DataAnalysis/RealWordRep/TimePoint1/TurbulenceTagging/TaggingDirectory"
