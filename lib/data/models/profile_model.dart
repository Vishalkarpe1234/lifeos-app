class ProfileModel {
  final int id;
  final int userId;
  final String? fullName;
  final String? title;
  final String? tagline;
  final String? bio;
  final String? introduction;
  final String? phone;
  final String? emailPublic;
  final String? location;
  final String? city;
  final String? state;
  final String? country;
  final String? profilePhotoUrl;
  final String? coverImageUrl;
  final String? resumeUrl;
  final List<String>? skills;
  final List<String>? languages;
  final Map<String, dynamic>? socialLinks;
  final List<dynamic>? education;
  final List<dynamic>? experience;
  final List<String>? achievements;
  final String? linkedinUrl;
  final String? githubUsername;
  final String? twitterUrl;
  final String? youtubeUrl;
  final String? instagramUrl;
  final String? blogUrl;

  const ProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.title,
    this.tagline,
    this.bio,
    this.introduction,
    this.phone,
    this.emailPublic,
    this.location,
    this.city,
    this.state,
    this.country,
    this.profilePhotoUrl,
    this.coverImageUrl,
    this.resumeUrl,
    this.skills,
    this.languages,
    this.socialLinks,
    this.education,
    this.experience,
    this.achievements,
    this.linkedinUrl,
    this.githubUsername,
    this.twitterUrl,
    this.youtubeUrl,
    this.instagramUrl,
    this.blogUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
    id: j['id'] ?? 0,
    userId: j['user_id'] ?? 0,
    fullName: j['full_name'],
    title: j['title'],
    tagline: j['tagline'],
    bio: j['bio'],
    introduction: j['introduction'],
    phone: j['phone'],
    emailPublic: j['email_public'],
    location: j['location'],
    city: j['city'],
    state: j['state'],
    country: j['country'],
    profilePhotoUrl: j['profile_photo_url'],
    coverImageUrl: j['cover_image_url'],
    resumeUrl: j['resume_url'],
    skills: (j['skills'] as List?)?.map((e) => e.toString()).toList(),
    languages: (j['languages'] as List?)?.map((e) => e.toString()).toList(),
    socialLinks: j['social_links'] as Map<String, dynamic>?,
    education: j['education'] as List?,
    experience: j['experience'] as List?,
    achievements: (j['achievements'] as List?)?.map((e) => e.toString()).toList(),
    linkedinUrl: j['linkedin_url'],
    githubUsername: j['github_username'],
    twitterUrl: j['twitter_url'],
    youtubeUrl: j['youtube_url'],
    instagramUrl: j['instagram_url'],
    blogUrl: j['blog_url'],
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'title': title,
    'tagline': tagline,
    'bio': bio,
    'introduction': introduction,
    'phone': phone,
    'email_public': emailPublic,
    'location': location,
    'city': city,
    'state': state,
    'country': country,
    'skills': skills,
    'languages': languages,
    'social_links': socialLinks,
    'education': education,
    'experience': experience,
    'achievements': achievements,
    'linkedin_url': linkedinUrl,
    'github_username': githubUsername,
    'twitter_url': twitterUrl,
    'youtube_url': youtubeUrl,
    'instagram_url': instagramUrl,
    'blog_url': blogUrl,
  };
}
