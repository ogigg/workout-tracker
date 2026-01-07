import { StatusBar } from "expo-status-bar";
import { useState } from "react";
import { ScrollView, Text, View } from "react-native";
import { Button, Provider as PaperProvider } from "react-native-paper";
import "./global.css";
import { AuthProvider } from "./src/context/AuthContext";

export default function App() {
  const [count, setCount] = useState(0);

  return (
    <AuthProvider>
      <PaperProvider>
        <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 16 }}>
          <View className="flex-1 items-center justify-center bg-white px-4">
            <Text className="text-3xl font-bold mb-2">Workout Tracker Mobile</Text>
            <Text className="text-base text-gray-600 mb-8 text-center">
              Using react-native-safe-area-context ✓
            </Text>
            <Text className="text-base text-gray-600 mb-8 text-center">
              Using react-native-safe-area-context ✓
            </Text>
            <Text className="text-base text-gray-600 mb-8 text-center">
              Using react-native-safe-area-context ✓
            </Text>

            <View className="bg-blue-50 p-6 rounded-lg mb-6">
              <Text className="text-lg text-center mb-4">
                Button Press Count: {count}
              </Text>
              <Button
                mode="contained"
                onPress={() => setCount(count + 1)}
                className="mb-2"
              >
                Press Me!
              </Button>
              <Button
                mode="outlined"
                onPress={() => setCount(0)}
              >
                Reset
              </Button>
            </View>

            <Text className="text-sm text-gray-500 text-center">
              The app is working correctly! 🎉
            </Text>

            <StatusBar style="auto" />
          </View>
        </ScrollView>
      </PaperProvider>
    </AuthProvider>
  );
}

