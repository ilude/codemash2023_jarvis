import os
import openai as ai
#ai.organization ='org-cBExy83sUBuAY7BRECeNb9Q0'

ai.api_key = os.environ.get('OPENAI_API_KEY')

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
    query_ai(os.environ.get('QUERY_TEXT'))
    print('It works!')

