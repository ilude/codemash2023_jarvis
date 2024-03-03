import os
import openai as ai
import pyaudio
import speech_recognition as sr

ai.api_key = os.environ.get('OPENAI_API_KEY')

def listen_for_wake_word():
    r = sr.Recognizer()
    print('accessing microphone')
    with sr.Microphone(0) as source:
        print('accessing microphone')
        audio = r.listen(source, 10, 3) #how long to listen 10 seconds, then how long once hearing wake word 3 seconds

        try:
            speech = r.recognize_google(audio)
            print(speech)
            if "hey jarvis" in speech.lower():
                print('\033[92mwake word detected\033[0m')
            else:
                print('\033[92mwake word not detected[0m')
        except sr.RequestError:
            print('Request Error')
        except sr.UnknownValueError:
            print('Unknown value error: could not hear you')
        except sr.WaitTimeoutError:
            print('wait timeout error: you took to long to talk')
    return
def query_ai(prompt):
    print('Prompt: ',prompt)
    completions = ai.Completion.create(
        engine = 'text-davinci-003',
        prompt = prompt,
        max_tokens = 256,
        n =1,
        stop = 'None',
        temperature = 0.5
    )
    message = completions.choices[0].text
    print('Message: ', message)
    return message


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    #query_ai(os.environ.get('QUERY_TEXT'))
    listen_for_wake_word()
    print('It works!')

