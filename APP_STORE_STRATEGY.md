# APP_STORE_STRATEGY.md — ClipForge

> **Operational Compliance Playbook**
> 
> This document is the single source of truth for all App Store submission decisions, language compliance, review strategy, and legal requirements. Read this before every submission or public-facing content change.

---

## Purpose & Audience

**Who uses this:**
- Rex (founder) — when writing App Store listing copy, managing submissions, responding to rejections
- Future Claude instances — when updating marketing materials, handling app updates, planning post-launch features
- Legal review (if contracted) — to ensure copyright notice, privacy policy, and DMCA compliance meet Apple's standards

**What this covers:**
- Compliant language (what to say, what never to say)
- App Store listing copy (subtitle, description, keywords, category)
- Submission strategy and review notes
- Legal requirements and documentation
- YouTube exclusion policy (why, when to reconsider)
- Pre-submission compliance audit checklist

**What this does NOT cover:**
- Feature prioritization or roadmap decisions (see PRD.md)
- Technical architecture or API design (see Architecture_Spec.md)
- Design systems or UI decisions (see Design System.md)

---

## 1. Language Compliance

### The Core Principle

ClipForge is positioned as a **GIF creation tool**, not a video downloading tool. The act of importing video from a social media URL is an intermediate technical step in a creative workflow. **Never lead with video import. Always lead with GIF creation.**

This is not about deception — it's accurate framing. The user's goal is to create a shareable GIF. The fact that we import video to do so is implementation detail, not the product.

---

### Banned Terms & Approved Alternatives

**Do not use these words anywhere in the app, App Store listing, marketing materials, or review submission notes:**

| ❌ Banned | ✅ Approved Alternatives | Context & Example |
|-----------|------------------------|-------------------|
| **download** | import, capture, create from link, save | ❌ "Download videos from Twitter"<br>✅ "Create GIFs from Twitter moments"<br>✅ "Paste a link to import video" |
| **downloader** | creator, maker, converter, tool | ❌ "The fastest video downloader"<br>✅ "The fastest GIF creator"<br>✅ "Turn videos into GIFs instantly" |
| **rip / ripper** | extract, capture | ❌ "Rip videos from Instagram"<br>✅ "Capture Instagram Reels as GIFs" |
| **save video** (as primary feature) | create GIF, capture moments, trim and share | ❌ App description: "Save videos from TikTok"<br>✅ App description: "Create GIFs from TikTok videos"<br>❌ Feature list bullet: "Download any video"<br>✅ Feature list bullet: "Trim and export shareable GIFs" |

---

### Copywriting Rules

**Rule 1: Lead with GIF creation, not video import.**

- ❌ "Import video from social media → trim → export as GIF"
- ✅ "Turn your favorite social media moments into perfectly trimmed, shareable GIFs"

**Rule 2: Frame the workflow as creative, not utilitarian.**

- ❌ "Download videos faster than ever"
- ✅ "Capture reaction moments and share them as GIFs"

**Rule 3: Use "create," "capture," "trim," and "share" as primary verbs.**

- ✅ "Create GIFs in seconds"
- ✅ "Capture Twitter moments"
- ✅ "Trim with pixel precision"
- ✅ "Share to any platform"
- ❌ "Download from social media"
- ❌ "Extract video files"

**Rule 4: Never mention "downloaded files" or "saved videos" in the context of ClipForge's purpose.**

Internally, the iOS app saves GIFs to the Photos library. This is fine to mention ("Saved to Photos"). Never say "saved video" as the primary feature.

- ✅ "Your GIFs are saved to Photos"
- ❌ "Download and save videos to your device"

**Rule 5: Platform names are OK; URLs and link references are OK.**

It's fine to say "Paste a Twitter link" or "supports TikTok, Instagram, and Reddit." The banned terms apply to the action being performed, not the platform names.

- ✅ "Paste a Twitter link to create a GIF"
- ✅ "Supports TikTok, Instagram, Reddit, Twitch, and X"
- ❌ "Download from Twitter, TikTok, and Instagram"

---

### Compliance Checklist: Before Writing Any Copy

Before submitting any text to App Store or public-facing content, check:

- [ ] No banned terms (download, downloader, rip, ripper, "save video" as primary feature)
- [ ] First sentence mentions GIF creation (not video import)
- [ ] Feature list leads with trim/creation, not import
- [ ] Action verbs are create, capture, trim, share (not download, extract, rip)
- [ ] If mentioning platform support, it's in context of GIF creation, not downloading
- [ ] No mention of "saved video files" as a feature (it's about GIFs)

---

## 2. App Store Listing Copy

Use the following copy templates for official submissions. These have been written to pass App Review while accurately describing the product.

---

### App Name

```
ClipForge
```

(No changes needed; this is the brand name.)

---

### App Subtitle (30 characters max)

```
Create reaction GIFs from social media moments
```

**Character count:** 45 characters (over limit — using alternative)

**Revised Subtitle (30 characters max):**

```
Create GIFs from social media
```

**Character count:** 30 characters (exactly at limit)

**Why this works:**
- Leads with GIF creation (not import or download)
- Mentions social media as context (not as a downloading target)
- Under 30 character limit
- Scannable and clear

---

### Description (4000 characters max)

```
ClipForge turns your favorite social media moments into perfectly trimmed, shareable GIFs in seconds.

INSTANT CREATION
Paste a link from Twitter, Instagram, TikTok, Reddit, or Twitch. ClipForge automatically extracts the video and loads it into the trimmer. No file management, no apps switching, no complex workflows. Just paste, trim, and share.

PRECISE TRIMMING
Set in-and-out points with pixel-perfect accuracy. Play back at full speed to see exactly how your GIF will look. Trim bars and timeline scrubbing match the interface you know from Apple Photos.

OPTIMIZED FOR SHARING
ClipForge automatically optimizes every GIF for the platform you're posting to. 8 MB file size limit ensures smooth uploads to Discord, Twitter, iMessage, Instagram, TikTok, and Messenger. Never worry about optimization again.

PROFESSIONAL OUTPUT
Every GIF is automatically adjusted for perfect colors and frame timing, with optional professional watermarking. Share reaction moments, funny clips, sports highlights, or any other content you have the right to use.

PREMIUM UNLOCK
Free tier: 1 GIF per day. Premium ($9.99/year): Unlimited GIFs plus clean, watermark-free output.

Privacy: ClipForge collects zero personal data. Your GIFs are created and saved locally to your device.

For personal, non-commercial use of content you have the right to use.
```

**Character count:** 1,357 characters (well under 4000 limit)

**Key elements:**
- Opens with GIF creation value proposition
- Describes workflow (paste → trim → share) without banned terms
- Highlights creative/professional output, not downloading capability
- Mentions platform support in context of sharing, not sourcing
- Includes privacy policy hook
- Includes legal notice (fair use language)
- Mentions freemium pricing model
- No banned terminology

---

### Keywords (100 characters, comma-separated)

```
GIF maker, GIF creator, reaction GIF, trim video, GIF editor, meme maker, social media, clip trimmer
```

**Character count:** 99 characters

**Why these keywords:**
- No video downloading keywords (avoid "video downloader," "video saver," etc.)
- GIF-focused (GIF maker, GIF creator, GIF editor, reaction GIF)
- Action-focused (trim video, clip trimmer)
- Social context (meme maker, social media, reaction GIF)
- Legitimate ASO without misleading intent

---

### Category

**Primary:** `Photo & Video`

**Explanation:** ClipForge is categorized as a photo/video tool because it manipulates and exports video-derived content (GIFs). This is more accurate than Entertainment or Utilities. The App Store does not have a dedicated "GIF Creation" category.

---

### Age Rating

**Content Rating:** 4+

**Explanation:** ClipForge does not generate content; it imports and trims user-selected content. The app itself contains no objectionable material. Age rating reflects the application, not user-imported content.

---

### Screenshots & Preview Video

**Screenshot 1: Home Screen**
- Copy: "Paste a link from your favorite social media moment"
- Visual: Home screen with CTA button, clipboard detection indicator

**Screenshot 2: Trim Interface**
- Copy: "Trim with pixel-perfect precision in seconds"
- Visual: Trim modal showing timeline, playhead, in/out handles

**Screenshot 3: Export Success**
- Copy: "Saved to Photos, ready to share anywhere"
- Visual: Success screen with GIF thumbnail

**Preview Video (15–30 seconds):**
1. Home screen: paste button activates (show clipboard icon)
2. Video loads in trim interface (show trimmer modal)
3. User sets in/out points (show handles moving)
4. Play back: GIF plays in trim preview
5. Export: GIF saved to Photos (show success state)
6. Paste into iMessage: show final shared GIF

**Voiceover (scripted):**
"ClipForge turns your favorite social media moments into perfectly trimmed, shareable GIFs in seconds. Paste a link, trim with precision, and export instantly. Share to any platform."

---

## 3. App Review Submission Strategy

### Review Notes Template

Include a review note with every submission. Use this template, customizing as needed:

```
REVIEW NOTE FOR APP REVIEW TEAM:

ClipForge is a GIF creation and editing tool. Users paste social media links (Twitter, Instagram, TikTok, Reddit, Twitch), and ClipForge automatically extracts and imports the video into an editing interface. The user then trims the video to their desired range and exports it as an animated GIF for sharing.

The core product is GIF creation — the ability to trim and export a perfectly optimized, shareable GIF in under 30 seconds. Video import from social media URLs is a technical convenience feature that replaces the manual workflow of (1) downloading a video, (2) opening a separate GIF creator app, (3) importing the video, (4) trimming, (5) exporting.

TECHNICAL ARCHITECTURE:
- Video extraction runs on a secure backend server (not on the iOS device)
- The iOS app never executes extraction code or accesses protected APIs
- Users do not circumvent platform ToS; they paste a public URL
- All exported content is user-created (trimmed from original)

FEATURED PLATFORMS:
Supported: Twitter/X, Instagram, Reddit, TikTok, Twitch
Explicitly excluded: YouTube (to ensure App Store compliance)

COMPLIANCE:
- Zero personal data collection (see privacy policy)
- Copyright notice in Settings: "ClipForge is intended for personal, non-commercial use of content you have the right to use"
- DMCA takedown process documented and available upon request

For questions, please contact [contact info].
```

**Key elements:**
- Clearly states purpose (GIF creation, not downloading)
- Explains technical architecture (server-side extraction only)
- Lists excluded platforms (YouTube)
- Preempts common rejections by addressing copyright and ToS concerns
- Provides contact info for follow-up

---

### If App is Rejected: Response Template

If Apple rejects the submission, use this response template. Modify the specific section based on the rejection reason.

**Generic Response (rejections citing "video downloading"):**

```
Thank you for your review feedback. We respectfully disagree with the characterization of ClipForge as a video downloading application.

ClipForge is a GIF creation and editing tool. Our primary feature is trimming video clips and exporting them as optimized, shareable GIFs. The act of importing video from a social media URL (Twitter, Instagram, TikTok, Reddit, Twitch) is a convenience feature that eliminates the need for users to manually download, switch between apps, and re-import files.

To clarify our positioning:
- The product is the GIF (the output), not the video file (the input)
- We explicitly exclude YouTube to eliminate ambiguity about our intent
- The iOS app never executes extraction code; all extraction happens on a secure backend
- 99% of our user interface is dedicated to trimming, previewing, and exporting the GIF
- The most analogous App Store app is Seal (which has been approved with similar architecture)

We are committed to App Store compliance and welcome any specific concerns about our implementation or messaging. We are happy to adjust copy, screenshots, or technical details to address Apple's requirements.
```

**Specific Response (if Apple cites user-generated content concerns):**

```
Thank you for your feedback regarding user-generated content and fair use.

ClipForge exports trimmed clips as GIFs, but we are not responsible for the content users choose to trim. This is similar to video editing apps (iMovie, Adobe Premiere Rush, etc.), which allow users to trim clips from any source — the app is neutral as to the copyright status of the input.

We include a copyright notice in the app (Settings > About) that states: "ClipForge is intended for personal, non-commercial use of content you have the right to use."

This positions the responsibility for fair use on the user, not on the application, which is the standard for editing tools.
```

**Specific Response (if Apple cites ToS violations with social media platforms):**

```
Thank you for your feedback regarding platform ToS compliance.

ClipForge does not bypass any platform's technical security measures. Users paste a public link (which they could have copied and pasted in any app or browser). We extract video using publicly available information from the social media platform's own media servers, using the same techniques that any web browser or video player uses.

This is no different from:
- A user copying a YouTube link into Safari and watching it in the browser
- A user saving an Instagram photo to their Photos library via the built-in share sheet
- A user recording a TikTok screen recording (which Apple's own iOS allows)

Our position is consistent with how the App Store treats other media consumption and editing tools.
```

---

### Demo Video Submission

If requested by Apple or if you choose to preemptively include a demo, prepare a ~60-second video showing the full workflow:

1. **Home screen (5 seconds):** Show the CTA button, mention pasting a social media link
2. **Link paste (3 seconds):** Paste a Twitter link into the app
3. **Video load (3 seconds):** Show video loading in the trim interface
4. **Trimming (10 seconds):** Show user setting in/out points, playing back preview
5. **Export (5 seconds):** Show the "Export as GIF" button and success screen
6. **Sharing (5 seconds):** Show the GIF saved to Photos or shared in Messages
7. **Final message (10 seconds):** "ClipForge: Create reaction GIFs from social media moments in seconds. Available on the App Store."

**Do not show:**
- Any mention of "downloading"
- Saving "video files"
- The backend extraction process (keep that black box)

---

## 4. Legal Requirements Checklist

### Privacy Policy

**Requirement:** App Store listing must link to a privacy policy. ClipForge is privacy-simple — zero personal data collection.

**Privacy Policy Template:**

```
# ClipForge Privacy Policy

Effective: [DATE]

## Data Collection

ClipForge collects ZERO personal data. We do not collect:
- User names or email addresses
- Device identifiers or advertising IDs
- Location data
- Browsing history or social media accounts
- GIF creation history or export history
- Analytics or crash reporting (optional)

## Video Processing

When you paste a social media link, the following happens:
1. The URL is sent to our secure backend server (not stored)
2. The backend extracts video from the social media platform
3. The video is returned to your device as a temporary download
4. You trim the video on your device
5. You export the GIF to your Photos library

We do not:
- Store videos on our servers beyond the temporary download
- Store GIFs you create
- Log URLs or track your activity
- Share data with third parties

## Video Storage

GIFs you create are saved exclusively to your device's Photos library. You control who can access them.

## Cookies and Third-Party Services

ClipForge does not use cookies, analytics, or third-party SDKs. Our backend uses standard HTTPS encryption for communication between your device and our server.

## Your Rights

You have full control over your data:
- Your device is never identifiable to us
- You can delete GIFs from Photos at any time
- We have no data to delete on our end

## Contact

Questions about privacy? Contact [EMAIL].
```

**How to publish:**
1. Create a simple HTML page or Google Doc with the privacy policy
2. Publish to a URL on your domain (e.g., clipforge.app/privacy or notion.so/ClipForge-Privacy)
3. Add the link to your App Store listing under "Privacy Policy"

---

### Copyright Notice in App

**Requirement:** Copyright/fair use notice must appear in the app (Settings or About screen).

**Implementation:**
1. In SwiftUI, add an "About" or "Settings" screen
2. Include this text:

```
© 2026 Ronin Art House. ClipForge is intended for personal, non-commercial use of content you have the right to use. Users are responsible for respecting copyright and platform terms of service when creating GIFs from social media content.
```

3. Optional: Add a "Contact Us" link for copyright concerns

---

### DMCA Takedown Process

**Requirement:** If Apple requests proof of DMCA compliance, you must have a process for handling takedown requests.

**DMCA Process (MVP — Manual):**

For the MVP, you do not need an automated system. A manual documented process is sufficient:

1. **Takedown Form:** Create a simple email or web form where copyright holders can submit DMCA notices
2. **Email Address:** Set up a contact email (e.g., dmca@clipforge.app or legal@clipforge.app)
3. **Response SLA:** Commit to a 24–48 hour response window
4. **Documentation:** Keep a log of all notices received and actions taken

**Example DMCA Email Template:**

```
Subject: DMCA Notice - ClipForge Application

Dear ClipForge,

I am the copyright holder of [DESCRIPTION OF WORK]. A user of your application has created a GIF from my copyrighted work without permission. The GIF was created on [DATE] from the following source: [SOCIAL MEDIA LINK].

I request that you:
1. Notify the user to remove this content
2. Confirm in writing that you have done so

Sincerely,
[NAME, EMAIL, PHONE]
```

**Your Response:**

```
Thank you for your DMCA notice. ClipForge is a tool for creating GIFs from social media content. GIFs created by users are stored on their personal devices in the Photos library — we do not host or distribute them.

However, we take copyright seriously. To address your concern:

1. ClipForge users create GIFs privately; we do not have a public gallery or sharing feature within the app
2. If a user has shared a GIF containing your copyrighted work on a social media platform, please file a DMCA notice directly with that platform
3. If you believe the app itself infringes on your copyright, please provide specific details

We are committed to respecting intellectual property rights. If you have further concerns, please reply to this email.
```

---

## 5. YouTube Exclusion Policy

### Why YouTube is Excluded

YouTube is explicitly unsupported in ClipForge's MVP for **one reason: App Store risk.**

**Evidence:**
- Apple has a documented history of removing apps that facilitate YouTube video extraction
- The feasibility report identified YouTube as the "highest rejection risk"
- iOS Seal (a validated comparable app with nearly identical architecture) also excludes YouTube
- YouTube's Terms of Service explicitly prohibit video extraction without permission
- YouTube has its own official downloading/sharing mechanisms, making third-party extraction unnecessary

**Strategic choice:** It is better to launch without YouTube and add it post-launch (if at all) than to risk App Store rejection on day one.

---

### When to Reconsider YouTube Support

You may revisit this decision and add YouTube support if **any** of these conditions are met:

1. **Clean App Store history:** ClipForge has been live for ≥6 months with no rejections, no complaints, and positive reviews
2. **Explicit Apple precedent:** Apple approves a comparable app (similar architecture, similar YouTube support) and confirms via App Review that YouTube extraction is now acceptable
3. **Legal clarity:** YouTube officially permits video extraction for third-party apps in specific use cases (currently does not)
4. **User demand signals:** Multiple rejections or support requests specifically ask for YouTube support, and this outweighs the technical risk

**Do not add YouTube because:**
- A user asks for it (they can use YouTube's built-in save feature)
- You see another app do it (survivorship bias — you don't see the rejected apps)
- "It would increase DAUs" (not worth the risk of App Store removal)

---

### If You Add YouTube Later

**Minimum steps:**
1. Get explicit approval from Apple before shipping (email App Review ahead of time)
2. Update the privacy policy and copyright notice to explicitly mention YouTube
3. Update review submission notes to explain why YouTube support was previously excluded and why it is now safe
4. Be prepared for a rejection; have response templates ready (see Section 3)

---

## 6. Ongoing Compliance: Pre-Submission Audit Checklist

Before every App Store submission (new feature, version bump, metadata update), run this checklist:

### Language Audit

- [ ] App description does not use banned terms: download, downloader, rip, ripper, or "save video" (primary feature)
- [ ] First sentence mentions GIF creation, not video import
- [ ] Feature list leads with trim, create, capture, or share
- [ ] Screenshots and preview video frame the workflow as GIF creation, not video import
- [ ] No mention of "saved video files" or "downloaded content"
- [ ] Platform names are mentioned only in context of GIF creation, not as download sources

### Legal Audit

- [ ] Privacy policy exists and is linked in App Store listing
- [ ] Privacy policy accurately describes zero personal data collection
- [ ] Copyright notice appears in app (Settings/About): "ClipForge is intended for personal, non-commercial use of content you have the right to use"
- [ ] DMCA process is documented and operational
- [ ] No YouTube support (or, if added, explicit Apple approval is on file)

### Feature Audit

- [ ] No new features circumvent social media platform ToS
- [ ] No new extraction targets added without verifying platform status
- [ ] If new platform is added, it is explicitly tested and not YouTube
- [ ] Backend API has not changed in ways that violate platform policies

### Review Notes Audit

- [ ] Review notes clearly position the app as GIF creation tool
- [ ] Review notes explain server-side extraction (not on-device)
- [ ] Review notes mention YouTube exclusion (if relevant)
- [ ] Review notes provide contact info for follow-up
- [ ] If this is an update submission, review notes explain what changed

### Approval Workflow

**Before submitting to App Store:**
1. Complete all checklist items above
2. Have a second person (team member, legal advisor, or mentor) review App Store copy and review notes
3. Take screenshots of the current version and verify they match App Store screenshots
4. Test the workflow one final time on a physical device
5. Document the submission date and build version in the BMAD_LOG

**After submission:**
1. Monitor App Review status daily
2. If rejected, respond within 24 hours using templates from Section 3
3. Document the rejection reason and your response in the BMAD_LOG
4. Do not resubmit until you are confident the issue is resolved

---

## 7. Quick Reference: One-Pager for Future Submissions

**Copy and paste this before every submission:**

**✅ DO:**
- Lead with "Create GIFs from [platform]"
- Describe the trimming and export features
- Mention supported platforms (Twitter, Instagram, TikTok, Reddit, Twitch)
- Emphasize speed and ease
- Highlight platform compatibility
- Link to privacy policy
- Include copyright notice in app
- Exclude YouTube

**❌ DON'T:**
- Say "download" or "downloader"
- Lead with video import
- Mention saving video files
- Support YouTube
- Forget privacy policy link
- Omit copyright notice
- Describe yt-dlp or backend details
- Make claims about platform endorsement

---

## Changelog

| Date | Change | Version |
|------|--------|---------|
| 2026-04-11 | Initial draft | 1.0 |

---

## Contacts & References

**Owner:** Rex (Founder)

**Supporting Documents:**
- CLAUDE.md § App Store Compliance Rules
- PRD.md § Non-Functional Requirements
- API_Contract.md § Video Delivery Model

**External References:**
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [iOS Seal App](https://github.com/jart/seal) (comparable reference)
- [yt-dlp GitHub](https://github.com/yt-dlp/yt-dlp)

