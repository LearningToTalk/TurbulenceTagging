# Include the auxiliary code files.
include ../Utilities/L2T-Utilities.praat
include ../StartupForm/L2T-StartupForm.praat
include ../Audio/L2T-Audio.praat
include ../WordList/L2T-WordList.praat
include ../L2T-SegmentationTextGrid/L2T-SegmentationTextGrid.praat
include ../TurbulenceLog/L2T-TurbulenceLog.praat
include ../TurbulenceTextGrid/L2T-TurbulenceTextGrid.praat

# Set the session parameters.
defaultExpTask = 2
defaultTestwave = 1
defaultActivity = 6

# Check whether all the objects that are necessary for turbulence tagging have
# been loaded to the Praat Objects list, and hence that the script is [ready]
# [.to_tag_turbulence_events].
procedure ready
	if (audio.praat_obj$ <> "") & 
		... (wordlist.praat_obj$ <> "") &
		... (segmentation_textgrid.praat_obj$ <> "") &
		... (turbulence_log.praat_obj$ <> "") &
		... (turbulence_textgrid.praat_obj$ <> "")
		.to_tag_turbulence_events = 1
	else
		.to_tag_turbulence_events = 0
	endif
endproc

# A procedure that sets the spectrogram settings for turbulence tagging.
# View range (Hz): 0.0 -- 15000.0
# Window size (s): 0.005
# Dynamic range (dB): 40.0
procedure spectrogram_settings
	editor 'turbulence_textgrid.praat_obj$'
		Spectrogram settings... 0.0 15000.0 0.005 40.0
		Pitch settings... 2000.0 2500.0 Hertz autocorrelation automatic
		Intensity settings... 25.0 100.0 "mean energy" 1
	endeditor
endproc

# Information about the current trial being tagged.
procedure current_trial
	# Determine the [.row_on_wordlist] that designates the current trial.
	select 'turbulence_log.praat_obj$'
	.row_on_wordlist = Get value... 1 'turbulence_log_columns.tagged_trials$'
	.row_on_wordlist = .row_on_wordlist + 1

	# Consult the WordList table to look-up the current trial's...
	select 'wordlist.praat_obj$'

	# ... Trial Number
	.trial_number$ = Get value... '.row_on_wordlist'
		... 'wordlist_columns.trial_number$'
	# ... Target Word
	.target_word$ = Get value... '.row_on_wordlist'
		... 'wordlist_columns.word$'
	# ... Target Consonant
	.target_c$ = Get value... '.row_on_wordlist'
		... 'wordlist_columns.target_c$'
	# ... Target Vowel
	.target_v$ = Get value... '.row_on_wordlist'
		... 'wordlist_columns.target_v$'

	# Determine the xmin, xmid, and xmax of the [interval] on the 'TrialNumber' 
	# tier of the segmented TextGrid that corresponds to the current trial.
	@interval: segmentation_textgrid.praat_obj$,
		... segmentation_textgrid_tiers.trial,
		... .trial_number$
	.xmin = interval.xmin
	.xmid = interval.xmid
	.xmax = interval.xmax
	.zoom_xmin = .xmin - 0.5
	.zoom_xmax = .xmax + 0.5
endproc

# Grab the segmentations of the current trial.
procedure segmentations_of_current_trial
	# Extract the Trial from the Segmentation TextGrid, and export the name
	# of the new TextGrid.
	.textgrid$ = segmentation_textgrid.praat_obj$
	@extract_interval: .textgrid$,
  		... current_trial.xmin,
		... current_trial.xmax
	.trial_textgrid$ = extract_interval.praat_obj$

	# Transform the extracted TextGrid down to a Table, and export the name 
	# of the new Table.
	@textgrid2table: .trial_textgrid$
	.trial_table$ = textgrid2table.praat_obj$

	# Subset the [.trial_table$] to just the rows on the Context tier.
	select '.trial_table$'
	Extract rows where column (text)... tier "is equal to" Context
	.segmentations_table$ = selected$()

	# Rename the [.segmentations_table$]
	@participant: turbulence_textgrid.write_to$,
		... session_parameters.participant_number$
	.table_obj$ = participant.id$ + "_" +
		... current_trial.trial_number$ + "_" +
		... "Segmentations"
	select '.segmentations_table$'
	Rename... '.table_obj$'
	.praat_obj$ = selected$()

	# Get the number of segmentations of the current trial.
	select '.praat_obj$'
	.n_segmentations = Get number of rows

	# Create string variables for identifiers of the segmentations.
	for i to .n_segmentations
		select '.praat_obj$'
		.context'i'$ = Get value... 'i' text
		.segmentation'i'$ = "'i'" + "--" + .context'i'$
	endfor

	# Clean up all of the intermediary Praat Objects.
	@remove: .trial_textgrid$
	@remove: .trial_table$
endproc

# A procedure for storing the possible Consonant Types.
procedure consonant_types
	.sib_fric$    = "Sibilant fricative"
	.sib_affr$    = "Sibilant affricate"
	.nonsib_fric$ = "Non-sibilant fricative"
	.nonsib_plos$ = "Non-sibilant plosive"
	.malaprop$    = "Malaprop"
	.other$       = "Other"

	# Gather the Consonant Types into a vector.
	.slot1$ = .sib_fric$
	.slot2$ = .sib_affr$
	.slot3$ = .nonsib_fric$
	.slot4$ = .nonsib_plos$
	.slot5$ = .malaprop$
	.slot6$ = .other$
	.length = 6
endproc

# Prompt the user to judge the consonant type of the response and add any
# supplementary notes.
procedure tagging_form
	.no_taggable_response$ = "No response is taggable"
	.missing_data$         = "MissingData"
	@consonant_types

	# Import string variables from [current_trial] namespace.
	.trial_number$ = current_trial.trial_number$
	.target_word$  = current_trial.target_word$
	.target_c$     = current_trial.target_c$
	.target_v$     = current_trial.target_v$
	.title$ = .trial_number$ + " :: " + .target_word$ + " :: " + .target_c$ + " :: " + .target_v$

	beginPause: .title$
		#comment: "Please listen to the current trial in its entirety."
		# Determine the taggable response.
		comment: "Which response would you like to tag?"
			optionMenu: "Response", 1
			for i to segmentations_of_current_trial.n_segmentations
				option: segmentations_of_current_trial.segmentation'i'$
			endfor
		option: .no_taggable_response$

		# Determine Consonant Type of the taggable response
		comment: "If there is a taggable response, what type of consonant was produced?"
			optionMenu: "Consonant type", 1
			for i to consonant_types.length
				option: consonant_types.slot'i'$
			endfor

		# Transcribe a sibilant fricative.
		comment: "If the consonant is a sibilant fricative (or an acceptable malapropism), please transcribe its Place."
		if current_trial.target_c$ == "s"
			optionMenu: "Fricative place", 1
				option: "s"
				option: "s:$S"
				option: "$S:s"
				option: "$S"
				option: "other"
		elif current_trial.target_c$ == "S"
			optionMenu: "Fricative place", 4
				option: "$s"
				option: "$s:S"
				option: "S:$s"
				option: "S"
				option: "other"
		endif

		# Allow the tagger to record notes about the trial.
		comment: "Would you like to record any notes for this trial?"
 			boolean: "BorderlineAffricate", 0
			boolean: "ConsonantSequence", 0
			boolean: "Quiet", 0
			boolean: "Clipping", 0
            boolean: "Deleted", 0
			boolean: "BackgroundNoise", 0
			boolean: "OverlappingResponse", 0
			boolean: "NonInitial", 0
			boolean: "Whistled", 0
			boolean: "Malaprop", 0
			sentence: "Malaprop word", ""

		#    Check if either consOnset or turbOffset needs to be tagged as well.
		#    comment: "Is it necessary to tag consOnset and turbOffset independently?"
		#    boolean: "consOnset", 0
		#    boolean: "turbOffset", 0

	.button = endPause: "Save progress & quit", "Tag it!", 2, 1

	if .button == 2
		# Export variables to the [response_to_tag] namespace.
		# By default, export the [.consOnset] and [.turbOffset] values to both be
		# 0.  This guards against the tagger accidentally clicking one of the check
		# boxes for these events.  The tagger's choice is restored below under the
		# blocks where {consonant_type$ == consonant_types.sib_fric$} or
		# {consonant_type$ == consonant_types.sib_affr$}.
		#  response_to_tag.consOnset  = 0
		#  response_to_tag.turbOffset = 0
		# Check to see if this trial had a taggable response.

		if response$ <> .no_taggable_response$
			# If this trial had a taggable response, then that segmentation is tagged
			# with the consonant label provided by the tagger.
			response_to_tag.repetition = response

			# Store the consonant_type$
			response_to_tag.consonant_type$ = consonant_type$

			# The value of the [.consonant_label$] variable depends on the adjudged
			# [consonant_type$]
			if consonant_type$ == consonant_types.sib_fric$
				# If the target consonant was produced as a SIBILANT FRICATIVE, then the
				# label of the ConsType tier is SibilantFricative;<transcription>.
				response_to_tag.consonant_label$ = consonant_type$ + ";" +
					... fricative_place$

				# Export the [.consOnset] and [.turbOffset] values as chosen by the
				# tagger.
				#      response_to_tag.consOnset  = consOnset
				#      response_to_tag.turbOffset = turbOffset
				elif consonant_type$ == consonant_types.sib_affr$
					# Export the [.consOnset] and [.turbOffset] values as chosen by the
					# tagger.
					#      response_to_tag.consOnset  = consOnset
					#      response_to_tag.turbOffset = turbOffset
					# Export the [.consonant_label$].
					response_to_tag.consonant_label$ = consonant_type$
				elif consonant_type$ == consonant_types.malaprop$
					# Export the [.consOnset] and [.turbOffset] values as chosen by the
					# tagger.
					#      response_to_tag.consOnset  = consOnset
					#      response_to_tag.turbOffset = turbOffset
					# Construct the ConsType label.

					while malaprop_word$ == ""
						@prompt_for_malaprop_word
					endwhile

					response_to_tag.consonant_label$ = consonant_type$ + ":" +
						... malaprop_word$ + ";" +
						... fricative_place$
				else
					response_to_tag.consonant_label$ = consonant_type$
				endif
			else
				# If this trial had no taggable response, then the FIRST segmentation is
				# tagged with the label: "MissingData"
				response_to_tag.repetition = 1
				response_to_tag.consonant_label$ = .missing_data$
				response_to_tag.consonant_type$  = .missing_data$
			endif

			# Concatenate the Notes together.
			response_to_tag.notes$ = ""

			# BorderlineAffricate
			if borderlineAffricate
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "BorderlineAffricate"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "BorderlineAffricate"
				endif
			endif

			# ConsonantSequence
			if consonantSequence
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "ConsonantSequence"				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "ConsonantSequence"
				endif
			endif

			# Quiet
			if quiet
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "Quiet"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "Quiet"
				endif
			endif

			# Clipping
			if clipping
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "Clipping"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "Clipping"
				endif
			endif
            
			# Deleted
			if deleted
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "Deleted"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "Deleted"
				endif
			endif
            
			# BackgroundNoise
			if backgroundNoise
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "BackgroundNoise"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "BackgroundNoise"
				endif
			endif

			# OverlappingResponse
			if overlappingResponse
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "OverlappingResponse"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "OverlappingResponse"
				endif
			endif

			# NonInitial
			if nonInitial
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "NonInitial"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + "NonInitial"
				endif
			endif

			# Whistled
			if whistled
				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "Whistled"
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + "Whistled"
				endif
			endif

			# Malaprop
			if malaprop
				while malaprop_word$ == ""
					@prompt_for_malaprop_word
				endwhile

				if response_to_tag.notes$ == ""
					response_to_tag.notes$ = "Malaprop" + ":" + malaprop_word$
				else
					response_to_tag.notes$ = response_to_tag.notes$ + ";" + 
						... "Malaprop" + ":" + malaprop_word$
				endif
			endif
		endif
	endif
endproc

# A procedure that prompts the user for the malapropism that the child
# produced.
procedure prompt_for_malaprop_word
	beginPause: "Malapropism" + " :: " + current_trial.trial_number$ + " :: " +
		... current_trial.target_word$
		comment: "What malapropism did the child produce?"
		sentence: "Malaprop word", ""
	endPause: "", "Continue", 2, 1
endproc

# A procedure for setting information about the response to tag.
procedure response_to_tag
	# The following variables are set by the procedure @tagging_form.
	#   .repetition
	#   .consonant_label$
	#   .consonant_type$
	#   .consOnset
	#   .turbOffset
	#   .notes$
	# Determine whether the produced consonant is sibilant.
	# [consonant_type$] is a global variable whose value is set when the user
	# judges the trial.

	if (.consonant_type$ == consonant_types.sib_fric$) |
		... (.consonant_type$ == consonant_types.sib_affr$) |
		... (.consonant_type$ == consonant_types.malaprop$)
		.is_sibilant = 1
	else
		.is_sibilant = 0
	endif

	# Determine the [boundary_times] of the response to tag.
	@boundary_times: segmentations_of_current_trial.praat_obj$,
		... .repetition,
		... segmentation_textgrid.praat_obj$,
		... segmentation_textgrid_tiers.context

	# Import the times from the [boundary_times] namespace.
	.xmin = boundary_times.xmin
	.xmid = boundary_times.xmid
	.xmax = boundary_times.xmax
	.duration = .xmax - .xmin

	# Set the limits of the zoom window.
	.zoom_xmin = .xmin - 0.25
	.zoom_xmax = .xmax + 0.25
endproc

# A procedure for inserting boundaries, which mark the extent of the response
# to tag, on an Interval [.tier] of the TextGrid that is displayed in the 
# Editor window during turbulence tagging.
procedure insert_boundaries .tier
	select 'turbulence_textgrid.praat_obj$'
	Insert boundary... '.tier'
		... 'response_to_tag.xmin'
	Insert boundary... '.tier'
		... 'response_to_tag.xmax'
endproc

# Add to the TextGrid, the ConsType information for the current response.
# A procedure for adding to the Turbulence Tagging TextGrid, the ConsType
# information for the response to tag.
procedure add_consonant_type
	# Insert the interval boundaries.
	@insert_boundaries: turbulence_textgrid_tiers.cons_type
	# Determine the interval number on the ConsType tier.
	@interval_at_time: turbulence_textgrid.praat_obj$,
		... turbulence_textgrid_tiers.cons_type,
		... response_to_tag.xmid
	# Label the interval.
	@label_interval: turbulence_textgrid.praat_obj$,
		... turbulence_textgrid_tiers.cons_type,
		... interval_at_time.interval,
		... response_to_tag.consonant_label$
endproc

# A procedure that adds, to the Turbulence Tagging TextGrid, the TurbNotes of
# the response to tag.
procedure add_turbulence_notes
	if response_to_tag.notes$ <> ""
	@insert_point: turbulence_textgrid.praat_obj$,
		... turbulence_textgrid_tiers.turb_notes,
		... response_to_tag.xmid,
		... response_to_tag.notes$
	endif
endproc

# A procedure that adds, to the Turbulence Tagging TextGrid, the ConsType,
# TurbEvents, and TurbNotes of the response to tag.
procedure transcribe_and_annotate_response
	# Add the ConsType.
	@add_consonant_type
	# Add the TurbNotes.
	@add_turbulence_notes
endproc

# A procedure that allows the user to iteratively tag turbulence events.
procedure tag_turbulence_events
	.cons_onset$ = "consOnset"
	.turb_onset$ = "turbOnset"
	.turb_offset$ = "turbOffset"
	.vot$ = "VOT"
	.vowel_end$ = "vowelEnd"

	if response_to_tag.is_sibilant
		.tagging_turbulence_events = 1
		while .tagging_turbulence_events
			# Import string variables from [current_trial] namespace.
			.trial_number$ = current_trial.trial_number$
			.target_word$  = current_trial.target_word$
			.target_c$     = current_trial.target_c$
			.target_v$     = current_trial.target_v$
 			.title$ = .trial_number$ + " :: " + .target_word$ + " :: " + .target_c$ + " :: " + .target_v$

			beginPause: "Tagging turbulence events" + " :: " + .title$
				comment: "In the Editor window, position the cursor where you'd like to tag an event."
				comment: "Select which event you'd like to tag."
				choice: "Turbulence event", 2
					option: .cons_onset$
					option: .turb_onset$
					option: .turb_offset$
					option: .vot$
					option: .vowel_end$
			.button = endPause: "", "Tag it!", "Extract trial", "Move on", 2, 1

			if .button == 2
				# Get the cursor position from the Editor window.
				editor 'turbulence_textgrid.praat_obj$'
					.event_time = Get cursor
				endeditor

				# The user's selection of 'Turbulence event' determines the event label.
				.event_label$ = turbulence_event$
				@insert_point: turbulence_textgrid.praat_obj$,
					... turbulence_textgrid_tiers.turb_events,
					... .event_time,
					... .event_label$
			elif .button == 3
				@extract_trial_as_example
			elif .button == 4
				.tagging_turbulence_events = 0
			endif
		endwhile
	endif
endproc

# # A procedure for setting the turbulence events' labels and times for the
# # response to tag.
# procedure turbulence_events
#   .cons_onset$  = "consOnset"
#   .turb_onset$  = "turbOnset"
#   .turb_offset$ = "turbOffset"
#   .vot$         = "VOT"
#   .vowel_end$   = "vowelEnd"
#   # Gather the turbulence event tags into a vector that is specific to the
#   # current response.
#   if response_to_tag.consOnset
#     .slot1$ = .cons_onset$
#     .slot2$ = .turb_onset$
#     if response_to_tag.turbOffset
#       .slot3$ = .turb_offset$
#       .slot4$ = .vot$
#       .slot5$ = .vowel_end$
#     else
#       .slot3$ = .vot$
#       .slot4$ = .vowel_end$
#     endif
#   else
#     .slot1$ = .turb_onset$
#     if response_to_tag.turbOffset
#       .slot2$ = .turb_offset$
#       .slot3$ = .vot$
#       .slot4$ = .vowel_end$
#     else
#       .slot2$ = .vot$
#       .slot3$ = .vowel_end$
#     endif
#   endif
#   .length = 3 + response_to_tag.consOnset + response_to_tag.turbOffset
#   # Determine the times at which the turbulence event tags should be dropped.
#   .time1 = response_to_tag.xmin + (0.1 * response_to_tag.duration)
#   .time'.length' = response_to_tag.xmax - (0.1 * response_to_tag.duration)
#   .increment = (.time'.length' - .time1) / (.length - 1)
#   for i from 2 to (.length - 1)
#     .time'i' = .time1 + (.increment * (i - 1))
#   endfor
# endproc
#
#
# # A procedure that adds, to the Turbulence Tagging TextGrid, the TurbEvents of
# # the response to tag.
# procedure tag_turbulence_events
#   @turbulence_events
#   for i to turbulence_events.length
#     @insert_point: turbulence_textgrid.praat_obj$,
#                ... turbulence_textgrid_tiers.turb_events,
#                ... turbulence_events.time'i',
#                ... turbulence_events.slot'i'$
#   endfor
# endproc
#
#
# # A procedure that pauses the script while the user adjusts the events on the
# # TurbEvents tier, and then asks the user to choose what she would like to do
# # next.
# procedure adjust_turb_events
#   .next_trial$ = "Move on to the next trial"
#   .extract$    = "Extract the trial that I just tagged"
#   .save_quit$  = "Save my progress & quit"
#   beginPause: current_trial.trial_number$ + " :: " +
#           ... current_trial.target_word$
#     comment: "Please adjust all of the event-points on the TurbEvents Tier."
#     comment: "Once you've finished that, let me know what you want to do next."
#     choice: "I want to", 1
#       option: .next_trial$
#       #option: .extract$
#       option: .save_quit$
#   endPause: "", "Do it!", 2, 1
#   .what_next$ = i_want_to$
# endproc

# A procedure for incrementing the number of trials tagged, as logged on the
# Turbulence Tagging Log.
procedure increment_trials_tagged
	select 'turbulence_log.praat_obj$'
	.n_segmented = Get value... 1 'turbulence_log_columns.tagged_trials$'
	.n_segmented = .n_segmented + 1
	Set numeric value... 1 'turbulence_log_columns.tagged_trials$' '.n_segmented'
	@timestamp
	select 'turbulence_log.praat_obj$'
	Set string value... 1 'turbulence_log_columns.end_time$' 'timestamp.time$'
endproc

# A procedure for saving the Turbulence Tagging Log and the
# Turbulence Tagging tiers.
procedure save_progress
	# Save the Turbulence Tagging Log.
	select 'turbulence_log.praat_obj$'
	Save as tab-separated file... 'turbulence_log.write_to$'

	# Save the Turbulence Tagging tiers.  This procedure is defined in the
	# L2T-TurbulenceTextGrid.praat script.
	@save_turbulence_tiers
endproc

# A procedure for clearing Praat's objects list.
procedure clear_objects_list
	@remove: audio.praat_obj$
	@remove: wordlist.praat_obj$
	@remove: segmentation_textgrid.praat_obj$
	@remove: turbulence_log.praat_obj$
	@remove: turbulence_textgrid.praat_obj$
endproc

# A procedure for breaking out of the top-level while-loop.
procedure quit_tagging
	continue_tagging = 0
endproc

# A procedure for congratulating a thanking the user once she has finished
# tagging a file in its entirety.
procedure congratulations_on_a_job_well_done
	beginPause: "Congratulations!"
		comment: "You've finished tagging!  Thank you for your hard work!"
		comment: "If you would like to tag another file, just re-run the script."
	endPause: "Don't click me", "Click me", 2, 1
endproc

# A procedure for controlling how the script proceeds once a trial has been
# tagged.
procedure move_on_from_current_trial
	# Increment the number of trials tagged, in order to log the user's progress.
	@increment_trials_tagged

	# Save the user's progress.
	@save_progress

	# Remove the Table of the current trial's segmentations.
	@remove: segmentations_of_current_trial.praat_obj$

	# If the [current_trial] is the last trial on the WordList, then break out of
	# the top-level while-loop.
	if current_trial.row_on_wordlist == wordlist.n_trials
		# Clean up Praat's Objects list.
		@clear_objects_list

		# Quit tagging.
		@quit_tagging

		# Congratulate the user on finishing a file.
		@congratulations_on_a_job_well_done
	endif
endproc

# A procedure for extracting the audio of the current trial.
procedure extract_trial_as_example
	.extract_directory$ = session_parameters.experiment_directory$ + "/" +
		... "TurbulenceTagging" + "/" + "ExtractedExamples"
	.extract_basename$ = session_parameters.experimental_task$ + "_" +
		... participant.id$ + "_" +
		... session_parameters.initials$ + "_" +
 		... current_trial.trial_number$ + "_" +
		... current_trial.target_word$
	.extract_filepath$ = .extract_directory$ + "/" + .extract_basename$ +
		... ".Collection"

	# Extract the audio of the current trial.
	select 'audio.praat_obj$'
	Extract part... 'current_trial.xmin' 'current_trial.xmax' rectangular 1.0 1
	Rename... '.extract_basename$'
	.wav_obj$ = selected$()

	# Extract the TextGrid of the current trial.
	select 'turbulence_textgrid.praat_obj$'
	Extract part... 'current_trial.xmin' 'current_trial.xmax' 1
	Rename... '.extract_basename$'
	.tg_obj$ = selected$()

	# Save the [.wav_obj$] and [.tg_obj$] as a Praat Collection.
	select '.wav_obj$'
	plus '.tg_obj$'
	Save as text file... '.extract_filepath$'
	# Clean up Praat's Objects list.
	@remove: .wav_obj$
	@remove: .tg_obj$
endproc

################################################################################
#  Main procedure                                                              #
################################################################################

# Set the session parameters.
@session_parameters: defaultExpTask, defaultTestwave, defaultActivity
#printline 'session_parameters.initials$'
#printline 'session_parameters.workstation$'
#printline 'session_parameters.experimental_task$'
#printline 'session_parameters.testwave$'
#printline 'session_parameters.participant_number$'
#printline 'session_parameters.activity$'
#printline 'session_parameters.analysis_directory$'
printline Data directory: 'session_parameters.experiment_directory$'

# Load the audio file
@audio

# Load the WordList.
@wordlist

# Load the checked segmented TextGrid.
@segmentation_textgrid

# Load the Turbulence Tagging Log.
@turbulence_log

# Load the Turbulence Tagging TextGrid.
@turbulence_textgrid

# Check if the Praat Objects list is [ready] to proceed 
# [.to_tag_turbulence_events].
@ready

if ready.to_tag_turbulence_events
	printline Ready to turbulence tag: 'turbulence_textgrid.praat_obj$'

	# Open an Editor window, displaying the Sound object and the 
	# Turbulence TextGrid.
	@open_editor: turbulence_textgrid.praat_obj$,
		... audio.praat_obj$

	# Set the spectrogram settings in the Editor window.
	@spectrogram_settings

	# Enter a while-loop, within which the tagging is performed.
	continue_tagging = 1

	while continue_tagging
		# Set information about the [current_trial].
		@current_trial

		# Determine the segmentations of the current trial.
		@segmentations_of_current_trial

		# Zoom to the current trial.
		@zoom: turbulence_textgrid.praat_obj$,
			... current_trial.zoom_xmin,
			... current_trial.zoom_xmax

		# Present the user with the [tagging_form], with which she can judge the 
		# trial.
		@tagging_form

		if tagging_form.button == 2
			# Set information about the [response_to_tag]
			@response_to_tag

			# Transcribe and annotate the response.
			@transcribe_and_annotate_response

			# Zoom to the tagged response.
			@zoom: turbulence_textgrid.praat_obj$,
				... response_to_tag.zoom_xmin,
				... response_to_tag.zoom_xmax

			# Pause the script to allow the user to tag the turbulence events.
			@tag_turbulence_events

			# Move on from the current trial.
			@move_on_from_current_trial

		elif tagging_form.button == 1
			# Clean up Praat's Objects list.
			@remove: segmentations_of_current_trial.praat_obj$

			@clear_objects_list

			# Quit tagging.
			@quit_tagging
		endif
	endwhile
endif