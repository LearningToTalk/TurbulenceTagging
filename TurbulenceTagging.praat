# Author: Patrick Reidy
# Date: 10 August 2013


# What are the criteria for deciding which segmented productions
# are tagged?
#   Context: Response
#            UnpromptedResponse
#            VoicePromptResponse
#            NonResponse
#            ***_ConsecTarget#
#   Repetition: 1
#               any other number other than 1
#   

# How do we want to analyze the fricative-target productions?
#   L2T longitudinal analyses.
#   * The traditional measure for tracking phonological development
#     and determining whether a child has acquired a given sound, is
#     a transcription of the child's productions relative to an adult
#     phonology.
#   * With this measure of phonological development, the question of
#     whether a child has a particular contrast is a yes-or-no
#     question.
#   * However, the growing literature of covert contrast reports that
#     there is a wide range of variation within the group of children
#     who by the traditional transcription-based measures of 
#     phonological development are determined to not have acquired
#     a contrast.
#   * One of the goals of the longitudinal study within the L2T 
#     project is to develop acoustic measures that capture the 
#     finer degrees of variation that are exhibited in cases of 
#     covert contrast.

# During turbulence tagging:
#   * Tags to mark the consonant category:
#       SibilantFricative
#       SibilantPlosive
#       NonSibilantPlosive
#       NonSibilantFricative
#       Other
#   * The Other consonant category tag will include productions that
#       1) are distorted, 2) begin as a WeakFricative and then 
#       transition into a Sibilant, or 3) begin as a Sibilant 
#       fricative and then transition into a plosive before 
#       optionally transitioning back into a fricative.
#   * Event tags:
#       onset, offset, vEnd
#   * Notes that 
#       Malaprop_[word]
#       Overlap
#       BackgroundNoise

# TextGrid Tiers.
#   * TurbulenceEvents: TextTier
#       onset, offset, vOffset
#   * ConsonantType: IntervalTier
#       interval boundaries are inherited from the segmentation data;
#       possible labels = Sibilant, NonSibilantPlosive, WeakFricative,
#                         Other
#   * ExcludeFromAnalysis: IntervalTier

# External data files.
#   * Segmented TextGrid
#   * Audio file
#   * Word List table
#   * Turbulence Tagging TextGrid
#   * Turbulence Tagging Log












# Local filesystem constants.
segmentDirectory$  = "/media/bluelacy/patrick/Code/L2T-TurbulenceTagging/Testing/SegmentedTextGrids"
audioDirectory$    = "/media/bluelacy/patrick/Code/L2T-TurbulenceTagging/Testing/Audio"
wordListDirectory$ = "/media/bluelacy/patrick/Code/L2T-TurbulenceTagging/Testing/WordLists"
tagLogDirectory$   = "/media/bluelacy/patrick/Code/L2T-TurbulenceTagging/Testing/TurbulenceTaggingLogs"
taggingDirectory$  = "/media/bluelacy/patrick/Code/L2T-TurbulenceTagging/Testing/TurbulenceTaggingTextGrids"

# Description of the Turbulence Tagging Log.
# A table with one row and the following columns (values).
# - TurbulenceTagger (string): the initials of the turbulence tagger.
# - StartTime (string): the date & time that the tagging began.
# - EndTime (string): the date & time that the tagging ended.
# - NumberOfTrials (numeric): the number of trials (rows) in the Word List table.
# - NumberOfTrialsTagged (numeric): the number of trials that have been 
#     tagged or intentionally skipped.
tagLogTagger        = 1
tagLogTagger$       = "TurbulenceTagger"
tagLogStart         = 2
tagLogStart$        = "StartTime"
tagLogEnd           = 3
tagLogEnd$          = "EndTime"
tagLogTrials        = 4
tagLogTrials$       = "NumberOfTrials"
tagLogTrialsTagged  = 5
tagLogTrialsTagged$ = "NumberOfTrialsTagged"

# Description of the Turbulence Tagging TextGrid.
# - Tier 1 (ConsonantType): Interval tier.
# - Tier 2 (TurbulenceEvents): Point tier.
# - Tier 3 (TurbulenceNotes): Interval tier.
tagTextGridConsType   = 1
tagTextGridConsType$  = "ConsType"
tagTextGridTurbEvent  = 2
tagTextGridTurbEvent$ = "TurbEvents"
tagTextGridTurbNotes  = 3
tagTextGridTurbNotes$ = "TurbNotes"

segTextGridTrial       = 1
segTextGridTrial$      = "Trial"
segTextGridWord        = 2
segTextGridWord$       = "Word"
segTextGridContext     = 3
segTextGridContext$    = "Context"
segTextGridRepetition  = 4
segTextGridRepetition$ = "Repetition"
segTextGridSegmNotes   = 5
segTextGridSegmNotes$  = "SegmNotes"

wordListTrialNumber  = 1
wordListTrialNumber$ = "TrialNumber"
wordListTargetWord   = 3
wordListTargetWord$  = "Word"
wordListTargetC      = 5
wordListTargetC$     = "TargetC"
wordListTargetV      = 6
wordListTargetV$     = "TargetV"



# Prompt the tagger for her initials.
beginPause ("Tagger's initials")
  comment ("Please enter your initials in the field below.")
  word    ("Your initials", "")
button = endPause ("Quit", "Continue", 2, 1)
if button == 2
  taggersInitials$ = your_initials$
endif

# Prompt the tagger to choose the subject's experimental ID.
Create Strings as file list... segmentedTextGrids 'segmentDirectory$'/*segm.TextGrid
select Strings segmentedTextGrids
Sort
beginPause ("Subject's experimental ID")
  comment ("Choose the subject's experimental ID from the menu below.")
  select Strings segmentedTextGrids
  nTextGrids = Get number of strings
  optionMenu ("Experimental ID", 1)
  for nTextGrid to nTextGrids
    select Strings segmentedTextGrids
    segmentedFilename$ = Get string... nTextGrid
    # 'segmentedFilename$' has the form:
    #   "(RealWordRep|NonWordRep)_::ExperimentalID::_XXsegm.TextGrid"
    # Parse the experimental ID from 'segmentedFilename$'.
    experimentalID$ = extractWord$(segmentedFilename$, "_")
    suffixPosition  = rindex(experimentalID$, "_")
    experimentalID$ = left$(experimentalID$, suffixPosition - 1)
    # [POSSIBLE EDIT]
    # The string variable experimentalID$ is the 9 character
    # alpha-numeric code that includes identifiers for the recording
    # site, subject number, study, age in months, gender, dialect,
    # and age cohort---e.g., 011L36MS2.
    # This could be shortened to just the recoding site, subject
    # number, and study---e.g., 011L.
    option ("'experimentalID$'")
  endfor
button = endPause ("Quit", "Continue", 2, 1)
if button == 2
  experimentalID$ = experimental_ID$
endif

# Read in the segmented TextGrid from the local filesystem.
segmentExpID$ = ""
nTextGrid = 0
while segmentExpID$ <> experimentalID$
  # Iterate through the 'segmentedTextGrids' Strings list, parsing
  # out the experimental ID from each filename and comparing it to
  # the experimental ID chosen by the tagger above.
  nTextGrid = nTextGrid + 1
  select Strings segmentedTextGrids
  segmentFilename$ = Get string... nTextGrid
  segmentExpID$  = extractWord$(segmentFilename$, "_")
  suffixPosition = rindex(segmentExpID$, "_")
  segmentExpID$  = left$(segmentExpID$, suffixPosition - 1)
endwhile
# Set the filepath and basename of the segmented TextGrid.
segmentBasename$ = left$(segmentFilename$, length(segmentFilename$) - 9)
segmentFilepath$ = "'segmentDirectory$'/'segmentFilename$'"
# Read in the segmented TextGrid.
Read from file... 'segmentFilepath$'
# Create a Table from the segmented TextGrid.
select TextGrid 'segmentBasename$'
Down to Table... 0 6 1 0
# Remove the 'segmentedTextGrids' Strings object from the Praat 
# objects list.
select Strings segmentedTextGrids
Remove

# Read in the audio file from the local filesystem.
# Create a Strings object from the list of .wav (and .WAV) files in
# the audio directory, and sort it alpha-numerically.
Create Strings as file list... audioFiles 'audioDirectory$'/*.wav
if (macintosh or unix)
  Create Strings as file list... audioFiles2 'audioDirectory$'/*.WAV
  select Strings audioFiles
  plus Strings audioFiles2
  Append
  select Strings audioFiles
  plus Strings audioFiles2
  Remove
  select Strings appended
  Rename... audioFiles
endif
select Strings audioFiles
Sort
nAudioFiles = Get number of strings
# Iterate through the 'audioFiles' Strings list, parsing out the 
# experimental ID from each filename and comparing it to the 
# experimental ID chosen by the tagger.
audioExpID$ = ""
nAudioFile  = 0
while (audioExpID$ <> experimentalID$) & (nAudioFile <= nAudioFiles)
  nAudioFile = nAudioFile + 1
  select Strings audioFiles
  audioFilename$ = Get string... nAudioFile
  audioExpID$ = extractWord$(audioFilename$, "_")
  audioExpID$ = left$(audioExpID$, length(audioExpID$) - 4)
endwhile
if nAudioFile <= nAudioFiles
  # If the 'nAudioFile' variable is less than the 'nAudioFiles'
  # constant, then an appropriately named audio file was found.
  # Set the filepath and basename of the audio file.
  audioBasename$ = left$(audioFilename$, length(audioFilename$) - 4)
  audioFilepath$ = "'audioDirectory$'/'audioFilename$'"
  # Read in the audio file.
  Read from file... 'audioFilepath$'
else
  # Otherwise, an appropriately named audio file was not found.
  # Print a message to the Praat output window.
  printline Error when loading the audio file:
  printline   No audio file with experimental ID:
  printline     'experimentalID$' 
  printline   was found in the audio directory:
  printline     'audioDirectory$'
  printline
endif
# Remove the 'audioFiles' Strings object from the Praat objects list.
select Strings audioFiles
Remove

# Read in the Word List table from the local filesystem.
Create Strings as file list... wordLists 'wordListDirectory$'/*WordList.txt
select Strings wordLists
Sort
nWordLists = Get number of strings
wordListExpID$ = ""
nWordList   = 0
while (wordListExpID$ <> experimentalID$) & (nWordList <= nWordLists)
  nWordList = nWordList + 1
  select Strings wordLists
  wordListFilename$ = Get string... nWordList
  wordListExpID$ = extractWord$(wordListFilename$, "_")
  suffixPosition = rindex(wordListExpID$, "_")
  wordListExpID$ = left$(wordListExpID$, suffixPosition - 1)
endwhile
if nWordList <= nWordLists
  # If the 'nWordList' variable is less than the 'nWordLists' constant,
  # then an appropriately named Word List table was found.
  # Set the filepath and basename of the Word List table.
  wordListBasename$ = left$(wordListFilename$, length(wordListFilename$) - 4)
  wordListFilepath$ = "'wordListDirectory$'/'wordListFilename$'"
  # Read in the Word List table.
  Read Table from tab-separated file... 'wordListFilepath$'
  # Get the number of trials in the Word List table.
  select Table 'wordListBasename$'
  nTrials = Get number of rows
else
  # Otherwise, an appropriately named Word List table was not found.
  # Print a message to the Praat output window.
  printline Error when loading the Word List table:
  printline   No Word List table with experimental ID:
  printline    'experimentalID$' 
  printline   was found in the Word List directory:
  printline     'wordListDirectory$'
  printline
endif
select Strings wordLists
Remove

# Look for a Turbulence Tagging Log and a Turbulence Tagging TextGrid
# on the local filesystem.
tagLogBasename$ = "'audioBasename$'_'taggersInitials$'turbulenceTagLog"
tagLogFilename$ = "'tagLogBasename$'.txt"
tagLogFilepath$ = "'tagLogDirectory$'/'tagLogFilename$'"
taggingBasename$ = "'audioBasename$'_'taggersInitials$'turb"
taggingFilename$ = "'taggingBasename$'.TextGrid"
taggingFilepath$ = "'taggingDirectory$'/'taggingFilename$'"
# Check if the 'tagLogFilepath$' points to a readable file on the
# local filesystem.
tagLogExists = fileReadable(tagLogFilepath$)
if tagLogExists
  # If an appropriately named Turbulence Tagging Log exists on the
  # filesystem.
  Read Table from tab-separated file... 'tagLogFilepath$'
  # Since a Turbulence Tagging Log exists, a Turbulence Tagging 
  # TextGrid should also exist on the local filesystem.
  tagTextGridExists = fileReadable(taggingFilepath$)
  if tagTextGridExists
    # Read in the Turbulence Tagging TextGrid.
    Read from file... 'taggingFilepath$'
  else
    # Print an error message to the Praat Output window.
    printline Error when loading the Turbulence Tagging TextGrid:
    printline   No Turbulence Tagging TextGrid with filename:
    printline     'taggingFilename$'
    printline   was found in the Turbulence Tagging TextGrid directory:
    printline     'taggingDirectory$'
    printline
  endif
else
  # Otherwise, create a Turbulence Tagging Log.
  Create Table with column names... 'tagLogBasename$' 1 'tagLogTagger$' 'tagLogStart$' 'tagLogEnd$' 'tagLogTrials$' 'tagLogTrialsTagged$'
  # Initialize the values of the Turbulence Tagging Log.
  currentTime$ = replace$(date$(), " ", "_", 0)
  select Table 'tagLogBasename$'
  Set string value... 1 'tagLogTagger$' 'taggersInitials$'
  Set string value... 1 'tagLogStart$' 'currentTime$'
  Set string value... 1 'tagLogEnd$' 'currentTime$'
  Set numeric value... 1 'tagLogTrials$' 'nTrials'
  Set numeric value... 1 'tagLogTrialsTagged$' 0
  # And create a Turbulence Tagging TextGrid.
  select Sound 'audioBasename$'
  To TextGrid... "'tagTextGridConsType$' 'tagTextGridTurbEvent$' 'tagTextGridTurbNotes$'" 'tagTextGridTurbEvent$'
  select TextGrid 'audioBasename$'
  Rename... 'taggingBasename$'
endif

# Open an Editor window
select TextGrid 'taggingBasename$'
plus Sound 'audioBasename$'
Edit
# Set the Spectrogram, etc., settings here.

# Determine the trial (i.e., the row of the Word List table) to start
# at.
select Table 'tagLogBasename$'
nTrialsTagged = Get value... 1 'tagLogTrialsTagged$'
trial = nTrialsTagged + 1

# Loop through the trials (i.e., the rows of the Word List table).
while trial <= nTrials
  # Get the Target Consonant of 'trial'
  select Table 'wordListBasename$'
  targetCons$ = Get value... 'trial' 'wordListTargetC$'
  # Check whether 'targetCons$' is "s" or "S".
  if (targetCons$ == "s") | (targetCons$ == "S")
    # If the Target Consonant of the current trial is a fricative,
    # then use the Trial Number of the current trial to determine
    # the XMin and XMax of the current trial.
    select Table 'wordListBasename$'
    trialNumber$ = Get value... 'trial' 'wordListTrialNumber$'
    select Table 'segmentBasename$'
    segTableRow  = Search column... text 'trialNumber$'
    trialXMin    = Get value... 'segTableRow' tmin
    trialXMax    = Get value... 'segTableRow' tmax
    trialXMid    = (trialXMin + trialXMax) / 2
    select TextGrid 'segmentBasename$'
    trialInterval = Get interval at time... 'segTextGridTrial' 'trialXMid'
    trialXMin     = Get start point... 'segTextGridTrial' 'trialInterval'
    trialXMax     = Get end point... 'segTextGridTrial' 'trialInterval'
    # Use the XMin and XMax of the current trial to extract that
    # portion of the segmented TextGrid. The TextGrid that this 
    # operation creates will have the name:
    # [TASK]_[EXP.ID]_[SEG.INITIALS]segm_part
    select TextGrid 'segmentBasename$'
    Extract part... 'trialXMin' 'trialXMax' 1
    # Convert the (extracted) TextGrid to a Table, which has the
    # same name as the TextGrid from which it was created:
    # [TASK]_[EXP.ID]_[SEG.INITIALS]segm_part
    select TextGrid 'segmentBasename$'_part
    Down to Table... 0 6 1 0
    # Remove the extracted TextGrid
    select TextGrid 'segmentBasename$'_part
    Remove
    # Subset the Table-cum-TextGrid to just the intervals on
    # the Context Tier that occur between the XMin and XMax of the
    # current trial. The resulting Table has the name:
    # [TASK]_[EXP.ID]_[SEG.INITIALS]segm_part_Context
    select Table 'segmentBasename$'_part
    Extract rows where column (text)... tier "is equal to" Context
    # Remove the Table-cum-TextGrid
    select Table 'segmentBasename$'_part
    Remove
    # Loop through the rows of the Table that contains the Context
    # labels of each segmented interval.
    select Table 'segmentBasename$'_part_Context
    nSegmentations = Get number of rows
    for segment to nSegmentations
      # Get the Context label for the segmentation.
      select Table 'segmentBasename$'_part_Context
      contextLabel$ = Get value... 'segment' text
      # Check that the segmentation was an actual response.
      if contextLabel$ <> "NonResponse"
        # If the segmentation wasn't a NonResponse, then it needs to
        # tagged.
        # Determine the XMin and XMax of the segmented interval.
        select Table 'segmentBasename$'_part_Context
        segmentXMin = Get value... 'segment' tmin
        segmentXMax = Get value... 'segment' tmax
        segmentXMid = (segmentXMin + segmentXMax) / 2
        select TextGrid 'segmentBasename$'
        segmentInterval = Get interval at time... 'segTextGridContext' 'segmentXMid'
        segmentXMin     = Get start point... 'segTextGridContext' 'segmentInterval'
        segmentXMax     = Get end point... 'segTextGridContext' 'segmentInterval'
        segmentXMid     = (segmentXMin + segmentXMax) / 2
        # Add interval boundaries, and zoom to the segmented interval
        select TextGrid 'taggingBasename$'
        Insert boundary... 'tagTextGridConsType' 'segmentXMin'
        Insert boundary... 'tagTextGridConsType' 'segmentXMax'
        Insert boundary... 'tagTextGridTurbNotes' 'segmentXMin'
        Insert boundary... 'tagTextGridTurbNotes' 'segmentXMax'
        # Zoom to the segmented interval in the editor window
        editor TextGrid 'taggingBasename$'
          zoomXMin = segmentXMin - 0.25
          zoomXMax = segmentXMax + 0.25
          Zoom... zoomXMin zoomXMax
        endeditor
        # Information to display to the tagger.
        # - TrialNumber
        # - TargetWord (English orthography)
        # - TargetConsonant (WorldBet transcription)
        # - TargetVowel (WorldBet transcription)
        select Table 'wordListBasename$'
        targetWord$  = Get value... 'trial' 'wordListTargetWord$'
        targetVowel$ = Get value... 'trial' 'wordListTargetV$'
        # The Pause window that is displayed to the tagger.
        if segment == 1
          quitButton$ = "Quit"
        else
          quitButton$ = " "
        endif
        beginPause ("Turbulence Tagging")
          comment ("Trial number: 'trialNumber$'")
          comment ("Target word: 'targetWord$'")
          comment ("Target consonant: 'targetCons$'")
          comment ("Target vowel: 'targetVowel$'")
          optionMenu ("Consonant type", 1)
            option ("Sibilant fricative")
            option ("Sibilant affricate")
            option ("Non-sibilant fricative")
            option ("Non-sibilant plosive")
            option ("Other")
          optionMenu ("Notes", 1)
            option (" ")
            option ("Malaprop")
            option ("OverlappingVoice")
            option ("BackgroundNoise")
          word ("Malaprop", "")
        buttonChoice = endPause ("'quitButton$'", "Tag it!", 2, 1)
        if buttonChoice == 1
          # Update the 'trials' variable so that the script breaks
          # out of the top-level while-loop.
          trial = nTrials + 1
        elsif buttonChoice == 2
          if notes$ == "Malaprop"
            notes$ = "Malaprop: 'malaprop$'"
          endif
          # Add the Consonant Type to the Turbulence Tagging TextGrid.
          select TextGrid 'taggingBasename$'
          consTypeInterval = Get interval at time... 'tagTextGridConsType' 'segmentXMid'
          Set interval text... 'tagTextGridConsType' 'consTypeInterval' 'consonant_type$'
          if notes <> 1
            select TextGrid 'taggingBasename$'
            turbNotesInterval = Get interval at time... 'tagTextGridTurbNotes' 'segmentXMid'
            Set interval text... 'tagTextGridTurbNotes' 'turbNotesInterval' 'notes$'
          endif
          if (consonant_type == 1) | (consonant_type == 2)
            # Automatically insert a `turbOnset` marker on the TurbEvents tier,
            # and prompt the tagger to adjust its position manually.
            select TextGrid 'taggingBasename$'
            Insert point... 'tagTextGridTurbEvent' 'segmentXMid' turbOnset
            beginPause ("Turbulence Tagging")
              comment ("Trial number: 'trialNumber$'")
              comment ("Target word: 'targetWord$'")
              comment ("Target consonant: 'targetCons$'")
              comment ("Target vowel: 'targetVowel$'")
              comment ("Adjust the `turbOnset` marker in the Editor window.")
            endPause ("Continue", 1, 1)
            # Determine the time of the `turbOnset` marker, as positioned
            # by the tagger.
            select TextGrid 'taggingBasename$'
            Extract part... 'segmentXMin' 'segmentXMax' 1
            select TextGrid 'taggingBasename$'_part
            Down to Table... 0 6 1 0
            select TextGrid 'taggingBasename$'_part
            Remove
            select Table 'taggingBasename$'_part
            turbOnsetRow = Search column... text turbOnset
            turbOnsetTime = Get value... 'turbOnsetRow' tmin
            Remove
            # Automatically insert a `VOT` marker on the TurbEvents tier,
            # and prompt the tagger to adjust its position manually.
            votDropTime = ('turbOnsetTime' + 'segmentXMax') / 2
            select TextGrid 'taggingBasename$'
            Insert point... 'tagTextGridTurbEvent' 'votDropTime' VOT
            beginPause ("Turbulence Tagging")
              comment ("Trial number: 'trialNumber$'")
              comment ("Target word: 'targetWord$'")
              comment ("Target consonant: 'targetCons$'")
              comment ("Target vowel: 'targetVowel$'")
              comment ("Adjust the `VOT` marker in the Editor window.")
            endPause ("Continue", 1, 1)
            # Determine the time of the `VOT` marker, as positioned by
            # the tagger.
            select TextGrid 'taggingBasename$'
            Extract part... 'segmentXMin' 'segmentXMax' 1
            select TextGrid 'taggingBasename$'_part
            Down to Table... 0 6 1 0
            select TextGrid 'taggingBasename$'_part
            Remove
            select Table 'taggingBasename$'_part
            votRow = Search column... text VOT
            votTime = Get value... 'votRow' tmin
            Remove
            # Prompt the tagger to position the cursor at the time where
            # a `turbOffset` tag should go.
            beginPause ("Turbulence Tagging")
              comment ("Trial number: 'trialNumber$'")
              comment ("Target word: 'targetWord$'")
              comment ("Target consonant: 'targetCons$'")
              comment ("Target vowel: 'targetVowel$'")
              comment ("In the Editor window, move the cursor to the `turbOffset` location, if applicable.")
            button = endPause ("No aspiration", "Mark turbOffset", 2, 1)
            aspirationPresent = (button == 2)
            if aspirationPresent
              # The tagger decided that there is aspiration to mark, so
              # compare whether the turbOffset is prior to 20 ms after the 
              # midpoint between turbOnset and VOT.
              editor TextGrid 'taggingBasename$'
                turbOffsetTime = Get cursor
              endeditor
              analysisWindowXMax = (('turbOnsetTime' + 'votTime') / 2) + 0.02
              turbOffsetNecessary = (turbOffsetTime < analysisWindowXMax)
              if turbOffsetNecessary
                select TextGrid 'taggingBasename$'
                Insert point... 'tagTextGridTurbEvent' 'turbOffsetTime' turbOffset
              endif
            endif
            # Automatically insert a `vowelEnd` marker on the TurbEvents tier,
            # and prompt the tagger to adjust its position manually.
            vowelEndDropTime = ('votTime' + 'segmentXMax') / 2
            select TextGrid 'taggingBasename$'
            Insert point... 'tagTextGridTurbEvent' 'vowelEndDropTime' vowelEnd
            beginPause ("Turbulence Tagging")
              comment ("Trial number: 'trialNumber$'")
              comment ("Target word: 'targetWord$'")
              comment ("Target consonant: 'targetCons$'")
              comment ("Target vowel: 'targetVowel$'")
              if (not aspirationPresent)
                comment ("There is no aspiration in the fricative, so a `turbOffset` marker was not inserted.")
              elsif (not turbOffsetNecessary)
                comment ("The aspiration came late in the fricative, so a `turbOffset` marker was not inserted.")
              endif
              comment ("Adjust the `vowelEnd` marker in the Editor window.")
            endPause ("Continue", 1, 1)
#            select TextGrid 'taggingBasename$'
#            Insert point... 'tagTextGridTurbEvent' 'segmentXMin' turbOnset
#            Insert point... 'tagTextGridTurbEvent' 'segmentXMid' turbOffset
#            Insert point... 'tagTextGridTurbEvent' 'segmentXMax' vowelEnd
#            beginPause ("Turbulence Tagging")
#              comment ("Adjust the Turbulence Event markers in the Editor window.")
#            buttonChoice = endPause ("Continue", 1, 1)
            # Add post-processing here, if desired and possible.
            # E.g., automatically moving the point marker to the nearest
            # zero-crossing.
          else
            # Do something if the consonant is non-sibilant or 'other'?
          endif
        endif
      else
        # Do something if the segmented interval was a NonResponse.
      endif
    endfor
    # Update the Turbulence Tagging Log only if the tagger chose not
    # to quit.
    if trial <= nTrials
      select Table 'tagLogBasename$'
      Set numeric value... 1 'tagLogTrialsTagged$' 'trial'
      Save as tab-separated file... 'tagLogFilepath$'
      select TextGrid 'taggingBasename$'
      Save as text file... 'taggingFilepath$'
    endif
    # Remove the Context sub-setted Table-cum-TextGrid.
    select Table 'segmentBasename$'_part_Context
    Remove
  else
    # If the Target Consonant of the current trial is not a fricative,
    # then just update the Turbulence Tagging Log
    select Table 'tagLogBasename$'
    Set numeric value... 1 'tagLogTrialsTagged$' 'trial'
    Save as tab-separated file... 'tagLogFilepath$'
  endif
  trial = trial + 1
endwhile


















