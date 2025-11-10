// Cloud Functions for PawMap
// Deploy with: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Function to automatically rank Top Picks based on ratings and reviews
exports.updateTopPicks = functions.pubsub.schedule('0 2 * * *') // Run daily at 2 AM
    .timeZone('America/New_York')
    .onRun(async (context) => {
        console.log('Starting Top Picks update...');
        
        try {
            // Get all places with their reviews
            const placesSnapshot = await db.collection('places').get();
            const places = [];
            
            for (const placeDoc of placesSnapshot.docs) {
                const place = placeDoc.data();
                const reviewsSnapshot = await db.collection('reviews')
                    .where('placeId', '==', placeDoc.id)
                    .get();
                
                const reviews = reviewsSnapshot.docs.map(doc => doc.data());
                
                // Calculate Top Picks score
                const score = calculateTopPicksScore(place, reviews);
                
                places.push({
                    id: placeDoc.id,
                    ...place,
                    topPicksScore: score,
                    reviewCount: reviews.length
                });
            }
            
            // Sort by Top Picks score
            places.sort((a, b) => b.topPicksScore - a.topPicksScore);
            
            // Update Top Picks collection
            const topPicksRef = db.collection('topPicks');
            await topPicksRef.doc('national').set({
                places: places.slice(0, 50), // Top 50 places
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                algorithm: 'rating_review_volume'
            });
            
            console.log(`Updated Top Picks with ${places.length} places`);
            
        } catch (error) {
            console.error('Error updating Top Picks:', error);
        }
    });

// Function to calculate Top Picks score
function calculateTopPicksScore(place, reviews) {
    if (reviews.length === 0) return 0;
    
    // Base score from average rating
    const avgRating = reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length;
    
    // Volume bonus (more reviews = higher score)
    const volumeBonus = Math.log(reviews.length + 1) * 0.5;
    
    // Recency bonus (recent reviews weighted more)
    const now = Date.now();
    const recentReviews = reviews.filter(review => 
        (now - review.createdAt.toMillis()) < (30 * 24 * 60 * 60 * 1000) // 30 days
    );
    const recencyBonus = (recentReviews.length / reviews.length) * 0.3;
    
    // Verification bonus
    const verificationBonus = place.isVerified ? 0.2 : 0;
    
    // Report penalty
    const reportPenalty = place.reportCount * 0.1;
    
    return avgRating + volumeBonus + recencyBonus + verificationBonus - reportPenalty;
}

// Function to moderate content (triggered by reports)
exports.moderateContent = functions.firestore
    .document('reports/{reportId}')
    .onCreate(async (snapshot, context) => {
        const report = snapshot.data();
        
        // Check if place has too many reports
        const reportsSnapshot = await db.collection('reports')
            .where('placeId', '==', report.placeId)
            .where('isResolved', '==', false)
            .get();
        
        if (reportsSnapshot.size >= 5) {
            // Flag place for review
            await db.collection('places').doc(report.placeId).update({
                needsReview: true,
                flaggedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
            // Notify admins
            await notifyAdmins(report.placeId, reportsSnapshot.size);
        }
    });

// Function to notify admins
async function notifyAdmins(placeId, reportCount) {
    const adminsSnapshot = await db.collection('admins').get();
    
    for (const adminDoc of adminsSnapshot.docs) {
        const admin = adminDoc.data();
        
        // Send notification (implement based on your notification system)
        console.log(`Notifying admin ${admin.email} about place ${placeId} with ${reportCount} reports`);
    }
}

// Function to update place ratings when reviews change
exports.updatePlaceRating = functions.firestore
    .document('reviews/{reviewId}')
    .onWrite(async (change, context) => {
        const review = change.after.exists ? change.after.data() : null;
        const placeId = review ? review.placeId : change.before.data().placeId;
        
        // Get all reviews for this place
        const reviewsSnapshot = await db.collection('reviews')
            .where('placeId', '==', placeId)
            .get();
        
        if (reviewsSnapshot.empty) {
            // No reviews, set rating to 0
            await db.collection('places').doc(placeId).update({
                rating: 0,
                reviewCount: 0
            });
            return;
        }
        
        // Calculate new average rating
        const reviews = reviewsSnapshot.docs.map(doc => doc.data());
        const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
        const averageRating = totalRating / reviews.length;
        
        // Update place with new rating
        await db.collection('places').doc(placeId).update({
            rating: Math.round(averageRating * 10) / 10, // Round to 1 decimal
            reviewCount: reviews.length
        });
    });

// Function to clean up old data
exports.cleanupOldData = functions.pubsub.schedule('0 3 * * 0') // Run weekly on Sunday at 3 AM
    .timeZone('America/New_York')
    .onRun(async (context) => {
        console.log('Starting data cleanup...');
        
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
        
        // Clean up old resolved reports
        const oldReportsSnapshot = await db.collection('reports')
            .where('isResolved', '==', true)
            .where('createdAt', '<', sixMonthsAgo)
            .get();
        
        const batch = db.batch();
        oldReportsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Cleaned up ${oldReportsSnapshot.size} old reports`);
    });

// Function to generate user statistics
exports.generateUserStats = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const userId = context.params.userId;
        
        // Get user's contributions
        const [placesSnapshot, reviewsSnapshot] = await Promise.all([
            db.collection('places').where('createdBy', '==', userId).get(),
            db.collection('reviews').where('userId', '==', userId).get()
        ]);
        
        // Calculate helpful votes received
        let helpfulVotes = 0;
        for (const reviewDoc of reviewsSnapshot.docs) {
            const review = reviewDoc.data();
            helpfulVotes += review.helpfulCount || 0;
        }
        
        // Update user stats
        await db.collection('userStats').doc(userId).set({
            userId: userId,
            placesAdded: placesSnapshot.size,
            reviewsWritten: reviewsSnapshot.size,
            photosUploaded: 0, // Calculate from image URLs
            helpfulVotesReceived: helpfulVotes,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
    });

// Function to send welcome email (if using email service)
exports.sendWelcomeEmail = functions.auth.user().onCreate(async (user) => {
    const email = user.email;
    const displayName = user.displayName || 'New User';
    
    // Send welcome email (implement with your email service)
    console.log(`Sending welcome email to ${email} for user ${displayName}`);
    
    // You can integrate with SendGrid, Mailgun, or other email services here
});

// Function to handle user deletion
exports.handleUserDeletion = functions.auth.user().onDelete(async (user) => {
    const userId = user.uid;
    
    // Delete user's data
    const batch = db.batch();
    
    // Delete user document
    batch.delete(db.collection('users').doc(userId));
    
    // Delete user stats
    batch.delete(db.collection('userStats').doc(userId));
    
    // Delete user preferences
    batch.delete(db.collection('userPreferences').doc(userId));
    
    // Delete user favorites
    batch.delete(db.collection('favorites').doc(userId));
    
    // Anonymize user's reviews (keep reviews but remove personal info)
    const reviewsSnapshot = await db.collection('reviews')
        .where('userId', '==', userId)
        .get();
    
    reviewsSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
            userId: 'deleted_user',
            userName: 'Deleted User'
        });
    });
    
    // Anonymize user's places
    const placesSnapshot = await db.collection('places')
        .where('createdBy', '==', userId)
        .get();
    
    placesSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
            createdBy: 'deleted_user'
        });
    });
    
    await batch.commit();
    console.log(`Cleaned up data for deleted user ${userId}`);
});

// Export all functions
module.exports = {
    updateTopPicks,
    moderateContent,
    updatePlaceRating,
    cleanupOldData,
    generateUserStats,
    sendWelcomeEmail,
    handleUserDeletion
};

