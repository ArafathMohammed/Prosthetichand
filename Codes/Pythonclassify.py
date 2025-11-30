import scipy.io
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPClassifier
import joblib

# Step 1: Load your MATLAB data
data = scipy.io.loadmat('training_data.mat')
X = data['featureList']
y = data['labelList'].ravel()  # ensure 1D

# Step 2: Split into train/test (optional, for validation)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Step 3: Standardize features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Step 4: Train ANN (MLPClassifier)
model = MLPClassifier(hidden_layer_sizes=(10,), max_iter=1000, random_state=42)
model.fit(X_train_scaled, y_train)

# Step 5: Save model and scaler as .pkl files
joblib.dump(model, 'trained_ann_model.pkl')
joblib.dump(scaler, 'scaler.pkl')

# Step 6: (Optional) Print test accuracy
test_accuracy = model.score(X_test_scaled, y_test)
print(f"Test accuracy: {test_accuracy*100:.2f}%")
