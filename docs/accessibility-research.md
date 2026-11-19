# Designing Hear Clock for blind and low-vision users

November 19, 2026

The clock should be easy to find by touch, read at a glance, and hear on request. These design choices draw on published participant studies. Feedback from people using Hear Clock itself is still needed.

## What users reported

- **Text size and speech serve different moments.** In a study of 45 adults with low vision using their own Android phones or iPhones, all 45 used larger text. Participants rated the built-in clock highly, and many valued being able to request speech for selected content. For Hear Clock, give the digits room and make the whole face speak on activation. A passing minute should stay quiet. [Mobile software aids for people with low vision](https://link.springer.com/article/10.1007/s11042-023-16639-5)
- **A readable color pair is personal.** WebAIM’s voluntary 2018 web survey received 248 responses. Among the 125 respondents who reported using a contrast mode, 89 used light text on dark, 32 used dark text on light, and four used lower contrast. Offer both light and dark starting points, preserve custom colors, and let people judge the result on the actual clock face. [WebAIM low-vision survey](https://webaim.org/projects/lowvisionsurvey2/)
- **People use location as well as speech.** In a study of eight experienced Android TalkBack users, participants touched familiar locations and swiped to a neighboring item when they missed. Some also adjusted speech speed with experience or when in a hurry. Keep the clock in a predictable place, make it one focus stop, and put the voice preview beside the rate control. [Jain et al., *Smartphone Usage by Expert Blind Users*, sections 4.1 and 4.5](https://www.microsoft.com/en-us/research/wp-content/uploads/2021/05/TalkBack_Log_Study_CHI_2021.pdf)

## Design checks

- Give each control at least 48 × 48 dp of touch area. With TalkBack, listen for the name, value, and available action together. The digits, hands, and speaker icon belong to one clock action. [Android touch targets](https://developer.android.com/guide/topics/ui/accessibility/apps), [Android grouping guidance](https://developer.android.com/guide/topics/ui/accessibility/principles).
- At 200% system font size, check that labels wrap, controls remain reachable, and saving still works on a narrow screen. Pair color swatches with names and a visible selection mark. Distinct hand lengths give an additional cue when two colors look alike. [Android font scaling](https://developer.android.com/about/versions/14/features#non-linear-font-scaling), [W3C guidance on color cues](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html).

## Questions to test with users

Invite blind TalkBack users and people who read visually with magnification, including people newer to those tools. Let each person use their usual phone settings. [W3C guidance on involving users](https://www.w3.org/WAI/test-evaluate/involving-users/)

1. From the launcher, can they find the widget and hear the time without coaching? Observe whether they locate it by touch or by swiping, and what gets focus first.
2. Which face and colors can they read comfortably at their preferred widget size? Ask them to identify the minutes, then change one digit or hand setting and find their way back.
3. Can they find a comfortable speech speed, preview it, and hear the same result from the widget? Record unexpected announcements and any step that needs a second attempt.
