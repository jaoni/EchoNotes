import 'package:echonotes/features/notes/domain/action_item.dart';
import 'package:echonotes/features/notes/domain/key_point.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/transcript_segment.dart';

/// Realistic notes for debug builds and tests: a team meeting, a lecture, an
/// interview, one still processing and one that failed. Dates are relative
/// to [now], so the list always reads "Today", "Yesterday" and so on.
List<Note> sampleNotes(DateTime now) => [
  Note(
    id: 'sample-processing',
    recordedAt: now.subtract(const Duration(minutes: 20)),
    duration: const Duration(minutes: 12, seconds: 18),
    status: NoteStatus.transcribing,
  ),
  _teamMeeting(now.subtract(const Duration(hours: 3))),
  _lecture(now.subtract(const Duration(days: 1, hours: 2))),
  Note(
    id: 'sample-failed',
    recordedAt: now.subtract(const Duration(days: 2, hours: 5)),
    duration: const Duration(minutes: 6, seconds: 40),
    status: NoteStatus.failed,
  ),
  _interview(now.subtract(const Duration(days: 4, hours: 1))),
];

/// What the pretend backend "writes" when a recording finishes processing.
/// It never listens to the audio, and says so.
Note withSampleResult(Note note) {
  final lines = [
    'This is where your transcript will appear.',
    'For now the app makes up these lines instead of listening.',
    'Once the backend is connected, you will see what was really said.',
  ];
  final step = note.duration ~/ lines.length;

  return note.copyWith(
    status: NoteStatus.ready,
    title: 'Sample notes for your recording',
    summary:
        'These are sample notes made on the phone, without listening to '
        'your recording. Real transcripts and notes arrive when the app is '
        'connected to the backend.',
    keyPoints: const [
      KeyPoint(text: 'Your recording went through every processing step.'),
      KeyPoint(text: 'Real key points will come from the conversation.'),
    ],
    actionItems: const [
      ActionItem(id: 'sample-1', text: 'Tick this item to try it out'),
      ActionItem(id: 'sample-2', text: 'Connect the backend in a later step'),
    ],
    tags: const ['sample'],
    transcript: [
      for (var i = 0; i < lines.length; i++)
        TranscriptSegment(start: step * i, end: step * (i + 1), text: lines[i]),
    ],
  );
}

Note _teamMeeting(DateTime recordedAt) => Note(
  id: 'sample-team-meeting',
  recordedAt: recordedAt,
  duration: const Duration(minutes: 32, seconds: 40),
  status: NoteStatus.ready,
  title: 'Weekly product sync',
  summary:
      "The team reviewed last week's beta feedback and agreed to make "
      'long recordings more reliable in the next sprint. Offline uploads '
      'move up the roadmap and sharing waits until after launch. Design will '
      "bring two home screen options to Thursday's review.",
  keyPoints: const [
    KeyPoint(
      text:
          'Beta testers love the summaries, but two lost long recordings '
          'when the app was closed.',
    ),
    KeyPoint(text: 'Reliability of long recordings is the top priority.'),
    KeyPoint(text: 'Offline uploads move up; sharing moves to after launch.'),
    KeyPoint(text: 'Home screen options will be reviewed on Thursday.'),
  ],
  actionItems: const [
    ActionItem(
      id: 'team-1',
      text: 'Priya: reproduce the lost recording bug on an older Android phone',
      isDone: true,
    ),
    ActionItem(id: 'team-2', text: 'Sam: draft the offline upload plan'),
    ActionItem(
      id: 'team-3',
      text: "Lena: bring two home screen options to Thursday's review",
    ),
    ActionItem(id: 'team-4', text: 'Share the beta survey results'),
  ],
  tags: const ['meeting', 'product', 'planning'],
  transcript: _segments([
    (_at(0, 0), "Okay, let's get started. First up is last week's beta."),
    (
      _at(0, 6),
      'Overall people really like the summaries. The action items got a '
          'lot of love.',
    ),
    (
      _at(0, 14),
      'But we had two reports of long recordings disappearing when the app '
          'was closed.',
    ),
    (
      _at(0, 23),
      'That one worries me most. If we lose a recording, we lose their trust.',
    ),
    (_at(0, 31), "Agreed. Let's make reliability the goal for next sprint."),
    (_at(0, 39), 'Priya, can you try to reproduce it on an older phone?'),
    (_at(0, 44), "Sure, I have one on my desk. I'll try it this afternoon."),
    (_at(0, 50), 'Great. Sam, what would it take to queue uploads offline?'),
    (
      _at(0, 57),
      'Not much, if we keep the file on the phone until the upload is '
          'confirmed.',
    ),
    (_at(1, 6), "Then let's move that up and push sharing until after launch."),
  ]),
);

Note _lecture(DateTime recordedAt) => Note(
  id: 'sample-lecture',
  recordedAt: recordedAt,
  duration: const Duration(minutes: 58, seconds: 12),
  status: NoteStatus.ready,
  title: 'Behavioral Economics, Lecture 4: Loss aversion',
  summary:
      'Loss aversion means people feel a loss about twice as strongly as an '
      'equal gain. The lecture covered the coin flip experiment, the '
      "endowment effect and how framing changes decisions. Next week's "
      'problem set applies these ideas to pricing and insurance.',
  keyPoints: const [
    KeyPoint(text: 'Losses weigh about twice as much as equal gains.'),
    KeyPoint(text: 'Endowment effect: we value things more once we own them.'),
    KeyPoint(
      text:
          'The same choice, framed as a loss or as a gain, leads to '
          'different decisions.',
    ),
    KeyPoint(text: 'Loss aversion helps explain why people over-insure.'),
  ],
  actionItems: const [
    ActionItem(id: 'lecture-1', text: 'Read chapter 5 before Tuesday'),
    ActionItem(id: 'lecture-2', text: 'Finish problem set 4 by Friday'),
    ActionItem(
      id: 'lecture-3',
      text: 'Review the mug experiment for the midterm',
    ),
  ],
  tags: const ['lecture', 'economics'],
  transcript: _segments([
    (_at(0, 0), 'Good afternoon. Today is all about losing things.'),
    (
      _at(0, 5),
      "Let's start with a bet. I flip a coin. Tails, you pay me ten dollars.",
    ),
    (_at(0, 12), 'Heads, I pay you. How much would I need to offer you?'),
    (
      _at(0, 19),
      'Most people ask for around twenty. That gap is loss aversion.',
    ),
    (
      _at(0, 27),
      'Losing ten dollars hurts about twice as much as winning ten feels '
          'good.',
    ),
    (_at(0, 36), 'Now, the famous mug experiment. Half the room gets a mug.'),
    (
      _at(0, 43),
      'Owners ask for about twice what buyers are willing to pay for it.',
    ),
    (_at(0, 51), 'Nothing about the mug changed. Only who owns it.'),
  ]),
);

Note _interview(DateTime recordedAt) => Note(
  id: 'sample-interview',
  recordedAt: recordedAt,
  duration: const Duration(minutes: 45, seconds: 5),
  status: NoteStatus.ready,
  title: 'Interview: senior mobile engineer',
  summary:
      'Second round interview with Jordan for the senior mobile role. Strong '
      'on Flutter architecture and testing, with clear examples from an '
      'offline-first app. Less experience with audio. The panel leans '
      'towards an offer, pending references.',
  keyPoints: const [
    KeyPoint(text: 'Six years in mobile, the last three mostly in Flutter.'),
    KeyPoint(text: 'Led an offline-first rewrite that halved crash reports.'),
    KeyPoint(text: 'Explained state management trade-offs clearly.'),
    KeyPoint(text: 'Little hands-on experience with audio or streaming.'),
  ],
  actionItems: const [
    ActionItem(
      id: 'interview-1',
      text: 'Share interview scores with the panel',
      isDone: true,
    ),
    ActionItem(id: 'interview-2', text: 'Call both references this week'),
    ActionItem(id: 'interview-3', text: 'Decide on an offer by Monday'),
  ],
  tags: const ['hiring', 'interview'],
  transcript: _segments([
    (_at(0, 0), 'Thanks for coming back, Jordan. How was the first round?'),
    (
      _at(0, 5),
      'Good, thanks. I enjoyed the pairing exercise more than I expected.',
    ),
    (_at(0, 12), "Let's talk about the offline-first rewrite you mentioned."),
    (
      _at(0, 18),
      'Sure. The old app lost data whenever the network dropped mid-save.',
    ),
    (
      _at(0, 26),
      'We moved every write into a local database first, then synced it.',
    ),
    (_at(0, 34), 'Crash reports dropped by about half within two releases.'),
    (_at(0, 41), 'Have you worked with audio at all?'),
    (
      _at(0, 45),
      'Only a little: playback in a podcast side project. Nothing live.',
    ),
  ]),
);

Duration _at(int minutes, int seconds) {
  return Duration(minutes: minutes, seconds: seconds);
}

/// Turns (start, text) lines into segments that each end where the next one
/// starts. The last one gets a short, made-up length.
List<TranscriptSegment> _segments(List<(Duration, String)> lines) {
  const lastLength = Duration(seconds: 6);
  return [
    for (var i = 0; i < lines.length; i++)
      TranscriptSegment(
        start: lines[i].$1,
        end: i + 1 < lines.length ? lines[i + 1].$1 : lines[i].$1 + lastLength,
        text: lines[i].$2,
      ),
  ];
}
